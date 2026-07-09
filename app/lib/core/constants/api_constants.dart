class ApiConstants {
  // Base URL for the FastAPI backend.
  // Using 127.0.0.1 because we have set up an ADB reverse proxy over USB.
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Endpoints
  static const String login = '$baseUrl/login';
  static const String devices = '$baseUrl/devices';
  static const String device = '$baseUrl/devices'; // Notice plural for REST standard
  static const String prediction = '$baseUrl/predictions';
  static const String recommendations = '$baseUrl/recommendations';
  static const String history = '$baseUrl/history';
}
