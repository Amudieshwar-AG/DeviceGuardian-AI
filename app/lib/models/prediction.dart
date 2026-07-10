class ActionableRecommendation {
  final String title;
  final String description;
  final String improvement;
  final String icon;
  final String color;

  ActionableRecommendation({
    required this.title,
    required this.description,
    required this.improvement,
    required this.icon,
    required this.color,
  });

  factory ActionableRecommendation.fromJson(Map<String, dynamic> json) {
    return ActionableRecommendation(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      improvement: json['improvement'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
    );
  }
}

class Prediction {
  final String deviceId;
  final int healthScore;
  final String riskLevel;
  final List<ActionableRecommendation> recommendations;
  final Map<String, dynamic> shapValues;
  final bool isAnomaly;
  final double anomalyScore;
  final double confidenceLevel;

  Prediction({
    required this.deviceId,
    required this.healthScore,
    required this.riskLevel,
    required this.recommendations,
    required this.shapValues,
    required this.isAnomaly,
    required this.anomalyScore,
    required this.confidenceLevel,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      deviceId: json['deviceId'] ?? '',
      healthScore: (json['healthScore'] ?? 100).toInt(),
      riskLevel: json['riskLevel'] ?? 'Low Risk',
      recommendations: (json['recommendations'] as List?)
              ?.map((item) => ActionableRecommendation.fromJson(item))
              .toList() ??
          [],
      shapValues: json['shapValues'] ?? {},
      isAnomaly: json['isAnomaly'] ?? false,
      anomalyScore: (json['anomalyScore'] ?? 0.0).toDouble(),
      confidenceLevel: (json['confidenceLevel'] ?? 100.0).toDouble(),
    );
  }
}
