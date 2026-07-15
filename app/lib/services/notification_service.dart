import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device.dart';

class AppNotificationService {
  static const _channel = MethodChannel('com.example.device_guardian_app/battery');
  
  // Track notified device statuses in memory to avoid spamming the same status repeatedly
  final Set<String> _notifiedDeviceStatuses = {};

  Future<void> showNativeNotification(String title, String body) async {
    try {
      print("[AppNotificationService] Checking notification permissions...");
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        print("[AppNotificationService] Permission is NOT granted (status: $status). Requesting permission...");
        final reqStatus = await Permission.notification.request();
        if (!reqStatus.isGranted) {
          print("[AppNotificationService] Permission denied by user.");
          return;
        }
      }
      
      print("[AppNotificationService] Invoking MethodChannel 'showNotification' with Title: '$title'...");
      final success = await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
      print("[AppNotificationService] showNotification invocation result: $success");
    } catch (e) {
      print("[AppNotificationService] Failed to show native notification: $e");
    }
  }

  void processDeviceUpdates(List<Device> devices) {
    print("[AppNotificationService] Processing device updates for ${devices.length} devices...");
    for (var device in devices) {
      final statusKey = "${device.id}_${device.status.name}";
      print("[AppNotificationService] Device: ${device.name}, Status: ${device.status.name}, Key: $statusKey");
      
      if (device.status == DeviceStatus.critical) {
        if (!_notifiedDeviceStatuses.contains(statusKey)) {
          _notifiedDeviceStatuses.add(statusKey);
          print("[AppNotificationService] Triggering critical notification for ${device.name}...");
          showNativeNotification(
            'Critical Risk Detected 🔴',
            '${device.name} is at High Risk. Immediate action recommended.',
          );
        }
      } else if (device.status == DeviceStatus.warning) {
        if (!_notifiedDeviceStatuses.contains(statusKey)) {
          _notifiedDeviceStatuses.add(statusKey);
          print("[AppNotificationService] Triggering warning notification for ${device.name}...");
          showNativeNotification(
            'Wear Detected 🟠',
            '${device.name} is showing moderate wear. Check recommendations.',
          );
        }
      } else if (device.status == DeviceStatus.healthy) {
        // If device returns to healthy, clean its previous critical/warning notification tracking
        // so that if it goes warning/critical again later, it will fire again.
        final removedCrit = _notifiedDeviceStatuses.remove("${device.id}_${DeviceStatus.critical.name}");
        final removedWarn = _notifiedDeviceStatuses.remove("${device.id}_${DeviceStatus.warning.name}");
        if (removedCrit || removedWarn) {
          print("[AppNotificationService] Device ${device.name} is healthy again. Resetting notification history.");
        }
      }
    }
  }
}

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService();
});
