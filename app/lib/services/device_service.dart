import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/device.dart';

class DeviceService {
  Future<List<Device>> getMyDevices() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) return [];

      // Fetch all device UUIDs mapped to this user
      final mappings = await Supabase.instance.client
          .from('device_mappings')
          .select('device_uuid')
          .eq('username', user.email!);

      if (mappings.isEmpty) return [];

      final deviceUuids = mappings.map((m) => m['device_uuid'] as String).toList();

      // Fetch telemetry data for these devices
      final telemetryData = await Supabase.instance.client
          .from('telemetry')
          .select('*')
          .inFilter('device_uuid', deviceUuids);

      List<Device> devices = [];
      for (var row in telemetryData) {
        final payload = row['payload'] as Map<String, dynamic>? ?? {};
        
        final batteryMap = payload['battery'] as Map<String, dynamic>? ?? {};
        final cpuMap = payload['cpu'] as Map<String, dynamic>? ?? {};
        final memoryMap = payload['memory'] as Map<String, dynamic>? ?? {};
        final storageMap = payload['storage'] as Map<String, dynamic>? ?? {};
        final systemMap = payload['system'] as Map<String, dynamic>? ?? {};

        final double temperature = (cpuMap['temperature_c'] ?? 30.0).toDouble();
        final double ramUsage = (memoryMap['ram_usage_percent'] ?? memoryMap['usage_percent'] ?? 50.0).toDouble();
        final double cpuUsage = (cpuMap['usage_percent'] ?? 20.0).toDouble();
        final double ssdUsage = (storageMap['disk_usage_percent'] ?? storageMap['usage_percent'] ?? 50.0).toDouble();
        final int batteryLevel = (batteryMap['percentage'] ?? batteryMap['level'] ?? 100).toInt();
        final bool isCharging = (batteryMap['charging'] ?? batteryMap['is_charging'] ?? false) == true;

        // Calculate a basic health score based on metrics
        int healthScore = 100;
        if (temperature > 40) healthScore -= 10;
        if (temperature > 50) healthScore -= 20;
        if (ramUsage > 90) healthScore -= 15;
        if (batteryLevel < 20) healthScore -= 5;
        if (healthScore < 0) healthScore = 0;
        
        String statusStr = 'healthy';
        if (healthScore < 60) statusStr = 'critical';
        else if (healthScore < 85) statusStr = 'warning';

        // Guess device type based on OS
        String osVersion = (systemMap['windows_version'] ?? '').toString().toLowerCase();
        String typeStr = osVersion.contains('windows') ? 'laptop' : 'phone';

        final Map<String, dynamic> fakeJson = {
          'id': row['device_uuid'],
          'name': row['device_name'] ?? systemMap['device_name'] ?? 'Unknown Device',
          'type': typeStr,
          'healthScore': healthScore,
          'batteryLevel': batteryLevel,
          'temperature': temperature,
          'cpuUsage': cpuUsage,
          'ramUsage': ramUsage,
          'ssdUsage': ssdUsage,
          'status': statusStr,
          'isCharging': isCharging,
          'lastSynced': row['updated_at'] ?? DateTime.now().toIso8601String(),
          'components': payload,
        };

        devices.add(Device.fromJson(fakeJson));
      }

      // Group devices by name and keep only the latest synced one to prevent duplicates
      final Map<String, Device> uniqueDevices = {};
      for (var device in devices) {
        final existing = uniqueDevices[device.name];
        if (existing == null) {
          uniqueDevices[device.name] = device;
        } else {
          try {
            final DateTime existingTime = DateTime.parse(existing.lastSynced);
            final DateTime newTime = DateTime.parse(device.lastSynced);
            if (newTime.isAfter(existingTime)) {
              uniqueDevices[device.name] = device;
            }
          } catch (e) {
            // Fallback: keep the existing one
          }
        }
      }

      return uniqueDevices.values.toList();
    } catch (e) {
      print("Error fetching devices from Supabase: $e");
      return [];
    }
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final myDevicesProvider = FutureProvider.autoDispose<List<Device>>((ref) async {
  final service = ref.read(deviceServiceProvider);
  
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());
  
  return service.getMyDevices();
});
