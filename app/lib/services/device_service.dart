import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../core/constants/api_constants.dart';

class DeviceService {
  /// Build a Device from a raw telemetry payload map
  Device _deviceFromPayload(String uuid, String deviceName, Map<String, dynamic> payload, String? updatedAt) {
    final systemMap = payload['system'] is Map ? Map<String, dynamic>.from(payload['system']) : {};
    
    // Parse battery level from payload
    final batteryMap = payload['battery'] is Map ? Map<String, dynamic>.from(payload['battery']) : {};
    final int batteryLevel = (batteryMap['level'] ?? batteryMap['percentage'] ?? 100).toInt();
    final bool isCharging = batteryMap['is_charging'] ?? batteryMap['charging'] ?? false;

    // Parse resource usages
    final cpuMap = payload['cpu'] is Map ? Map<String, dynamic>.from(payload['cpu']) : {};
    final double cpuUsage = (cpuMap['usage_percent'] ?? 20.0).toDouble();
    final double temperature = (cpuMap['temperature_c'] ?? cpuMap['gpu_temperature_c'] ?? 35.0).toDouble();

    final storageMap = payload['storage'] is Map ? Map<String, dynamic>.from(payload['storage']) : {};
    final double ssdUsage = (storageMap['usage_percent'] ?? storageMap['disk_usage_percent'] ?? 50.0).toDouble();

    final memoryMap = payload['memory'] is Map ? Map<String, dynamic>.from(payload['memory']) : {};
    final double ramUsage = (memoryMap['usage_percent'] ?? memoryMap['ram_usage_percent'] ?? 50.0).toDouble();

    // RUL and health
    final healthPred = payload['health_prediction'] is Map ? Map<String, dynamic>.from(payload['health_prediction']) : {};
    final double rul = (payload['native_remaining_useful_life_months'] ?? healthPred['remaining_useful_life_months'] ?? 36.0).toDouble();
    
    final nativeHealth = payload['native_battery_health_percentage'];
    String osVersion = (systemMap['windows_version'] ?? systemMap['device_name'] ?? '').toString().toLowerCase();
    String typeStr = (osVersion.contains('windows') || osVersion.contains('lap') || osVersion.contains('ashwin')) ? 'laptop' : 'phone';

    // Calculate healthScore applying operational deductions for phones
    int healthScore;
    if (typeStr == 'phone') {
      double baseHealth = 100.0;
      if (nativeHealth != null) {
        baseHealth = (nativeHealth as num).toDouble();
      } else {
        baseHealth = 80.0 + 20.0 * (rul / 36.0);
      }
      
      double deductions = 0.0;
      if (temperature > 38.0) {
        deductions += (temperature - 38.0) * 1.5;
      }
      if (temperature > 42.0) {
        deductions += (temperature - 42.0) * 1.0;
      }
      if (ssdUsage > 75.0) {
        deductions += (ssdUsage - 75.0) * 0.4;
      }
      if (cpuUsage > 80.0) {
        deductions += (cpuUsage - 80.0) * 0.2;
      }
      if (ramUsage > 80.0) {
        deductions += (ramUsage - 80.0) * 0.3;
      }
      healthScore = (baseHealth - deductions).round().clamp(0, 100);
    } else {
      healthScore = (80 + 20 * (rul / 36.0)).round();
      if (nativeHealth != null) {
        healthScore = (nativeHealth as num).toInt();
      }
    }
    
    if (healthScore > 100) healthScore = 100;
    if (healthScore < 0) healthScore = 0;

    String statusStr = 'healthy';
    if (healthScore < 75) statusStr = 'critical';
    else if (healthScore < 85) statusStr = 'warning';

    return Device.fromJson({
      'id': uuid,
      'name': deviceName,
      'type': typeStr,
      'healthScore': healthScore,
      'batteryLevel': batteryLevel,
      'temperature': temperature,
      'cpuUsage': cpuUsage,
      'ramUsage': ramUsage,
      'ssdUsage': ssdUsage,
      'status': statusStr,
      'isCharging': isCharging,
      'lastSynced': updatedAt ?? DateTime.now().toIso8601String(),
      'components': payload,
    });
  }

  Future<List<Device>> getMyDevices() async {
    // ── Try Supabase (online mode) ────────────────────────────────────────
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        final mappings = await Supabase.instance.client
            .from('device_mappings')
            .select('device_uuid')
            .eq('username', user.email!);

        final prefs = await SharedPreferences.getInstance();
        final hiddenList = prefs.getStringList('hidden_devices') ?? [];
        
        final deviceUuids = mappings
            .map((m) => m['device_uuid'] as String)
            .where((uuid) => !hiddenList.contains(uuid))
            .toList();

        if (deviceUuids.isEmpty) return [];

        final telemetryData = await Supabase.instance.client
            .from('telemetry')
            .select('*')
            .inFilter('device_uuid', deviceUuids);

        List<Device> devices = [];
        final List<Future<void>> futures = [];

        for (var row in telemetryData) {
          final deviceUuid = row['device_uuid'] as String;
          
          Map<String, dynamic> payload = {};
          if (row['payload'] is String) {
            try {
              payload = jsonDecode(row['payload']) as Map<String, dynamic>;
            } catch (_) {}
          } else if (row['payload'] is Map) {
            payload = Map<String, dynamic>.from(row['payload']);
          }

          futures.add(() async {
            try {
              final response = await http.get(
                Uri.parse('${ApiConstants.baseUrl}/devices/$deviceUuid'),
              ).timeout(const Duration(seconds: 4));

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body) as Map<String, dynamic>;
                final double temperature = (data['temperature'] ?? 30.0).toDouble();
                final double ramUsage = (data['ram'] ?? 50.0).toDouble();
                final double cpuUsage = (data['cpu'] ?? 20.0).toDouble();
                final double ssdUsage = (data['ssd'] ?? 50.0).toDouble();
                final int batteryLevel = (data['battery'] ?? 100).toInt();
                final int aiHealthScore = (data['healthScore'] ?? 100).toInt();
                final String statusStr = data['status'] ?? 'healthy';
                final String typeStr = data['type'] ?? 'phone';

                devices.add(Device.fromJson({
                  'id': deviceUuid,
                  'name': data['name'] ?? payload['system']?['device_name'] ?? row['device_name'] ?? 'My Device',
                  'type': typeStr,
                  'healthScore': aiHealthScore, // XGBoost AI Score
                  'batteryLevel': batteryLevel,
                  'temperature': temperature,
                  'cpuUsage': cpuUsage,
                  'ramUsage': ramUsage,
                  'ssdUsage': ssdUsage,
                  'status': statusStr.toLowerCase(),
                  'isCharging': statusStr.toLowerCase() == 'charging',
                  'lastSynced': data['lastUpdated'] ?? row['updated_at'] ?? DateTime.now().toIso8601String(),
                  'components': payload,
                }));
              } else {
                devices.add(_deviceFromPayload(deviceUuid, row['device_name'] ?? 'My Device', payload, row['updated_at']));
              }
            } catch (e) {
              print("Error fetching AI metrics for $deviceUuid: $e");
              devices.add(_deviceFromPayload(deviceUuid, row['device_name'] ?? 'My Device', payload, row['updated_at']));
            }
          }());
        }

        await Future.wait(futures);

        // Deduplicate by name, keep latest
        final Map<String, Device> uniqueDevices = {};
        for (var device in devices) {
          final existing = uniqueDevices[device.name];
          if (existing == null) {
            uniqueDevices[device.name] = device;
          } else {
            try {
              final DateTime existingTime = DateTime.parse(existing.lastSynced);
              final DateTime newTime = DateTime.parse(device.lastSynced);
              if (newTime.isAfter(existingTime)) uniqueDevices[device.name] = device;
            } catch (_) {}
          }
        }
        
        return uniqueDevices.values
            .where((device) => !hiddenList.contains(device.id))
            .toList();
      }
    } catch (e) {
      print("Supabase unavailable, switching to offline mode: $e");
    }

    // ── OFFLINE FALLBACK: use local UUID + Render backend ─────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final localUuid = prefs.getString('official_device_uuid');
      if (localUuid == null) return [];

      // Fetch latest device data from Render backend (the correct endpoint)
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devices/$localUuid'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Render backend returns flat fields, convert to payload format
        final payload = {
          'cpu': {'usage_percent': data['cpu'] ?? 20.0, 'temperature_c': data['temperature'] ?? 34.0},
          'battery': {'level': data['battery'] ?? 75, 'is_charging': false},
          'memory': {'usage_percent': data['ram'] ?? 50.0},
          'storage': {'usage_percent': data['ssd'] ?? 40.0},
          'system': {'device_name': data['name'] ?? 'My Device'},
        };
        return [_deviceFromPayload(localUuid, data['name'] ?? 'My Device', payload, data['lastUpdated'])];
      }

      // If no telemetry yet, return a placeholder so the home screen isn't blank
      return [
        Device.fromJson({
          'id': localUuid,
          'name': 'This Device',
          'type': 'phone',
          'healthScore': 85,
          'batteryLevel': 75,
          'temperature': 34.0,
          'cpuUsage': 25.0,
          'ramUsage': 50.0,
          'ssdUsage': 40.0,
          'status': 'healthy',
          'isCharging': false,
          'lastSynced': DateTime.now().toIso8601String(),
          'components': {},
        }),
      ];
    } catch (e) {
      print("Offline fallback error: $e");
      return [];
    }
  }

  Future<void> removeDevice(String deviceId) async {
    try {
      // 1. Delete from backend SQLite
      try {
        await http.delete(Uri.parse('${ApiConstants.baseUrl}/devices/$deviceId'))
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        print("Backend delete error: $e");
      }
      
      // 2. Try to delete from Supabase (might fail silently due to RLS policies missing DELETE permission)
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        await Supabase.instance.client
            .from('device_mappings')
            .delete()
            .eq('device_uuid', deviceId)
            .eq('username', user.email!);
      }
      
      // 3. Add to local hidden list so it disappears instantly regardless of RLS
      final prefs = await SharedPreferences.getInstance();
      final hiddenList = prefs.getStringList('hidden_devices') ?? [];
      if (!hiddenList.contains(deviceId)) {
        hiddenList.add(deviceId);
        await prefs.setStringList('hidden_devices', hiddenList);
      }
    } catch (e) {
      print("Error removing device: $e");
      throw Exception("Failed to remove device");
    }
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final myDevicesProvider = FutureProvider.autoDispose<List<Device>>((ref) async {
  final service = ref.read(deviceServiceProvider);

  final timer = Timer(const Duration(seconds: 10), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  return service.getMyDevices();
});

