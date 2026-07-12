import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/telemetry_service.dart';
import '../../services/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AndroidFlowScreen extends StatefulWidget {
  const AndroidFlowScreen({super.key});

  @override
  State<AndroidFlowScreen> createState() => _AndroidFlowScreenState();
}

class _AndroidFlowScreenState extends State<AndroidFlowScreen> with WidgetsBindingObserver {
  final Map<String, bool> _permissions = {
    'Battery': false,
    'Storage': false,
    'Usage Stats': false,
    'Notifications': false,
  };

  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final ApiService _apiService = ApiService();
  bool _isRegistering = false;

  bool get _allGranted => _permissions.values.every((v) => v);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExistingPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExistingPermissions();
    }
  }

  Future<void> _checkExistingPermissions() async {
    final Map<String, bool> updated = {};
    
    // 1. Check Notifications (POST_NOTIFICATIONS)
    final notificationStatus = await Permission.notification.status;
    updated['Notifications'] = notificationStatus.isGranted;

    // 2. Check Storage (READ/WRITE & MANAGE)
    final storageStatus = await Permission.storage.status;
    final manageStorageStatus = await Permission.manageExternalStorage.status;
    updated['Storage'] = storageStatus.isGranted || manageStorageStatus.isGranted;

    // 3. Check Battery Optimizations
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final prefs = await SharedPreferences.getInstance();
    final batteryManuallyToggled = prefs.getBool('battery_permission_toggled_manually') ?? false;
    updated['Battery'] = batteryStatus.isGranted || batteryManuallyToggled;

    // 4. Check Usage Stats via Native Channel
    bool usageStatsGranted = false;
    try {
      usageStatsGranted = await const MethodChannel('com.example.device_guardian_app/battery')
          .invokeMethod('checkUsageStatsPermission');
    } catch (e) {
      debugPrint("Error checking usage stats permission: $e");
    }
    updated['Usage Stats'] = usageStatsGranted;

    if (mounted) {
      setState(() {
        _permissions.addAll(updated);
      });
    }
  }

  Future<void> _togglePermission(String key) async {
    bool granted = false;
    
    if (key == 'Notifications') {
      final status = await Permission.notification.request();
      granted = status.isGranted;
    } else if (key == 'Storage') {
      final status = await Permission.storage.request();
      granted = status.isGranted;
      if (!granted) {
        final manageStatus = await Permission.manageExternalStorage.request();
        granted = manageStatus.isGranted;
      }
    } else if (key == 'Battery') {
      final status = await Permission.ignoreBatteryOptimizations.request();
      granted = status.isGranted;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('battery_permission_toggled_manually', true);
      } catch (_) {}
      granted = true; // OEM OS fallback: ensure switch is toggled green once attempted
    } else if (key == 'Usage Stats') {
      try {
        await const MethodChannel('com.example.device_guardian_app/battery')
            .invokeMethod('requestUsageStatsPermission');
        // Let lifecycle observer check again on app resume
        return;
      } catch (e) {
        debugPrint("Error requesting usage stats: $e");
      }
    }

    setState(() {
      _permissions[key] = granted;
    });
  }

  Future<void> _registerDevice() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      // 1. Get real device info
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceName = '${androidInfo.brand} ${androidInfo.model}'.trim();
      
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('official_device_uuid');
      if (deviceId == null) {
        deviceId = androidInfo.id;
        await prefs.setString('official_device_uuid', deviceId);
      }

      // 2. Get real battery percentage
      final batteryLevel = await _battery.batteryLevel;

      final temperature = await getRealBatteryTemperature();
      final storageUsage = await getRealStorageUsage();
      final ramUsage = await getRealRamUsage();
      final cpuUsage = getSimulatedCpuUsage();

      // 3. Prepare payload for FastAPI
      final payload = {
        "deviceId": deviceId,
        "name": deviceName,
        "deviceType": "phone",
        "cpu": cpuUsage,
        "ram": ramUsage,
        "battery": batteryLevel,
        "temperature": temperature,
        "ssd": storageUsage,
        "status": "Healthy",
        "timestamp": DateTime.now().toIso8601String()
      };

      // 4. Send to backend
      final success = await _apiService.registerDevice(payload);
      
      if (success) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email != null) {
          try {
            await Supabase.instance.client.from('device_mappings').upsert({
              'device_uuid': deviceId,
              'username': user.email!,
              'device_name': deviceName,
            }, onConflict: 'device_uuid,username');
          } catch (e) {
            print("Failed to save device mapping to Supabase: $e");
          }
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          final hiddenList = prefs.getStringList('hidden_devices') ?? [];
          if (hiddenList.contains(deviceId)) {
            hiddenList.remove(deviceId);
            await prefs.setStringList('hidden_devices', hiddenList);
          }
        } catch (e) {
          print("Failed to unhide device: $e");
        }
      }
      
      if (success && mounted) {
        // Show success snackbar and redirect
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device registered successfully!'), backgroundColor: AppTheme.success),
        );
        // Start background telemetry sync
        final container = ProviderScope.containerOf(context);
        container.read(telemetryServiceProvider).start(intervalSeconds: 30);
        container.invalidate(myDevicesProvider);
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register device.'), backgroundColor: AppTheme.critical),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.critical),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Android'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Required Permissions', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'DeviceGuardian needs these permissions to monitor your phone\'s health effectively.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: ListView(
                children: [
                  _buildPermissionCard('Battery', PhosphorIcons.batteryFull(), 'To monitor battery degradation'),
                  const SizedBox(height: 16),
                  _buildPermissionCard('Storage', PhosphorIcons.hardDrives(), 'To check for disk errors'),
                  const SizedBox(height: 16),
                  _buildPermissionCard('Usage Stats', PhosphorIcons.chartBar(), 'To analyze CPU/RAM trends'),
                  const SizedBox(height: 16),
                  _buildPermissionCard('Notifications', PhosphorIcons.bell(), 'To alert you of critical issues'),
                ],
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_allGranted && !_isRegistering) ? _registerDevice : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allGranted ? AppTheme.primaryColor : Theme.of(context).cardColor,
                ),
                child: _isRegistering 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register Device'),
              ),
            ).animate(target: _allGranted ? 1 : 0).shimmer(duration: 1.seconds),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(String title, IconData icon, String subtitle) {
    final isGranted = _permissions[title]!;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? AppTheme.success.withOpacity(0.2) : AppTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isGranted ? AppTheme.success : AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: isGranted,
            onChanged: (val) => _togglePermission(title),
            activeColor: AppTheme.success,
            activeTrackColor: AppTheme.success.withOpacity(0.3),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
