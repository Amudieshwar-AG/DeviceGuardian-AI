class Prediction {
  final String deviceId;
  final int healthScore;
  final String riskLevel;
  final List<String> recommendations;
  final Map<String, dynamic> shapValues;

  Prediction({
    required this.deviceId,
    required this.healthScore,
    required this.riskLevel,
    required this.recommendations,
    required this.shapValues,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      deviceId: json['deviceId'] ?? '',
      healthScore: (json['healthScore'] ?? 100).toInt(),
      riskLevel: json['riskLevel'] ?? 'Low Risk',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      shapValues: json['shapValues'] ?? {},
    );
  }
}
