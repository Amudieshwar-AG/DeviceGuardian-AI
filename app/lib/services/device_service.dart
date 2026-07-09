import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';

class DeviceService {
  Future<List<Device>> getMyDevices() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      Device(
        id: '1',
        name: 'Lenovo IdeaPad Slim 5',
        type: DeviceType.laptop,
        healthScore: 94,
        batteryLevel: 91,
        temperature: 43.0,
        status: DeviceStatus.healthy,
        lastSynced: 'Just now',
        components: {
          'SSD': 'Healthy',
          'CPU': 'Normal',
          'RAM': 'Good',
        }
      ),
      Device(
        id: '2',
        name: 'Samsung Galaxy S24',
        type: DeviceType.phone,
        healthScore: 96,
        batteryLevel: 87,
        temperature: 34.0,
        status: DeviceStatus.healthy,
        lastSynced: '5 mins ago',
        components: {
          'Storage': 'Healthy',
          'Battery': 'Normal',
        }
      ),
    ];
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final myDevicesProvider = FutureProvider<List<Device>>((ref) {
  final service = ref.read(deviceServiceProvider);
  return service.getMyDevices();
});
