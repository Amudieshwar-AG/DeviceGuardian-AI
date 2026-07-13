class ApiConstants {
  // Toggle this to false when compiling the release build (.apk) for the jury
  static const bool isDevelopment = false;

  // Base URLs
  static const String devUrl = 'http://127.0.0.1:8000';
  static const String prodUrl = 'https://deviceguardian-ai.onrender.com';

  static String get baseUrl => isDevelopment ? devUrl : prodUrl;

  // Endpoints
  static String get login => '$baseUrl/login';
  static String get devices => '$baseUrl/devices';
  static String get device => '$baseUrl/devices'; 
  static String get prediction => '$baseUrl/predictions';
  static String get recommendations => '$baseUrl/recommendations';
  static String get history => '$baseUrl/history';
}
