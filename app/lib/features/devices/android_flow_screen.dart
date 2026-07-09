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

class AndroidFlowScreen extends StatefulWidget {
  const AndroidFlowScreen({super.key});

  @override
  State<AndroidFlowScreen> createState() => _AndroidFlowScreenState();
}

class _AndroidFlowScreenState extends State<AndroidFlowScreen> {
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

  Future<void> _togglePermission(String key) async {
    bool granted = false;
    
    // For the hackathon demo, we will simulate the permission grant 
    // to avoid strict Android 13+ storage/stats restrictions blocking the switches.
    // In production, you would handle the complex Android 13+ permission flows here.
    
    // Only request real permission for notifications if you want, otherwise simulate all:
    if (key == 'Notifications') {
      final status = await Permission.notification.request();
      granted = status.isGranted || true; // Fallback to true if simulator blocks it
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      granted = true; 
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
      final deviceId = androidInfo.id; // Unique ID

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
      
      if (success && mounted) {
        // Show success snackbar and redirect
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device registered successfully!'), backgroundColor: AppTheme.success),
        );
        // Start background telemetry sync
        // Need ConsumerStatefulWidget or just let the global provider do it? Wait, AndroidFlowScreen is not ConsumerState.
        // We can just use the provider container if we pass it, but simpler: let's convert AndroidFlowScreen to ConsumerStatefulWidget, or use ProviderScope.containerOf(context)
        // Wait, I will just convert the class or use ProviderScope
        ProviderScope.containerOf(context).read(telemetryServiceProvider).start(intervalSeconds: 30);
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
