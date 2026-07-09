import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../core/services/api_service.dart';

class DeviceService {
  final ApiService _apiService = ApiService();

  Future<List<Device>> getMyDevices() async {
    try {
      return await _apiService.getDevices();
    } catch (e) {
      // In case the backend is down, return empty for now to avoid crashing UI
      print("Warning: Backend might be offline. Returning empty list. Error: $e");
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
