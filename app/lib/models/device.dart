enum DeviceType { laptop, phone, tablet }
enum DeviceStatus { healthy, warning, critical }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final int healthScore;
  final int batteryLevel;
  final double temperature;
  final DeviceStatus status;
  final String lastSynced;
  final Map<String, dynamic> components;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.healthScore,
    required this.batteryLevel,
    required this.temperature,
    required this.status,
    required this.lastSynced,
    required this.components,
  });
}
