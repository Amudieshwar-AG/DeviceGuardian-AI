class Telemetry {
  final double cpu;
  final double ram;
  final double battery;
  final double temperature;
  final double storage;

  Telemetry({
    required this.cpu,
    required this.ram,
    required this.battery,
    required this.temperature,
    required this.storage,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      cpu: (json['cpu'] ?? 0).toDouble(),
      ram: (json['ram'] ?? 0).toDouble(),
      battery: (json['battery'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      storage: (json['storage'] ?? json['ssd'] ?? 0).toDouble(),
    );
  }
}
