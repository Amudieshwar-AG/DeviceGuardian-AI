enum DeviceType { laptop, phone, tablet }
enum DeviceStatus { healthy, warning, critical, supportContacted }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final int healthScore;
  final int batteryLevel;
  final double temperature;
  final double cpuUsage;
  final double ramUsage;
  final double ssdUsage;
  final DeviceStatus status;
  final bool isCharging;
  final String lastSynced;
  final Map<String, dynamic> components;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.healthScore,
    required this.batteryLevel,
    required this.temperature,
    required this.cpuUsage,
    required this.ramUsage,
    required this.ssdUsage,
    required this.status,
    required this.isCharging,
    required this.lastSynced,
    required this.components,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    // Determine type
    DeviceType parsedType = DeviceType.laptop;
    String typeStr = (json['deviceType'] ?? json['type'] ?? 'laptop').toString().toLowerCase();
    if (typeStr.contains('phone') || typeStr.contains('mobile')) {
      parsedType = DeviceType.phone;
    } else if (typeStr.contains('tablet')) {
      parsedType = DeviceType.tablet;
    }

    // Parse status
    DeviceStatus parsedStatus = DeviceStatus.healthy;
    String statusStr = (json['status'] ?? 'healthy').toString().toLowerCase();
    if (statusStr.contains('warn')) parsedStatus = DeviceStatus.warning;
    if (statusStr.contains('crit')) parsedStatus = DeviceStatus.critical;
    if (statusStr.contains('contact')) parsedStatus = DeviceStatus.supportContacted;
    
    bool isCharging = statusStr.contains('charg') || (json['isCharging'] == true);

    return Device(
      id: json['deviceId'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Device',
      type: parsedType,
      healthScore: (json['health'] ?? json['healthScore'] ?? 100).toInt(),
      batteryLevel: (json['battery'] ?? json['batteryLevel'] ?? 100).toInt(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      cpuUsage: (json['cpu'] ?? json['cpuUsage'] ?? 0).toDouble(),
      ramUsage: (json['ram'] ?? json['ramUsage'] ?? 0).toDouble(),
      ssdUsage: (json['ssd'] ?? json['ssdUsage'] ?? 0).toDouble(),
      status: parsedStatus,
      isCharging: isCharging,
      lastSynced: json['timestamp'] ?? json['lastSynced'] ?? 'Just now',
      components: json['components'] ?? {},
    );
  }
}
