class ApiConstants {
  // Base URL for the FastAPI backend.
  // Change this to the deployed URL or network IP if testing on an actual device.
  static const String baseUrl = 'http://10.230.111.57:8000';

  // Endpoints
  static const String login = '$baseUrl/login';
  static const String devices = '$baseUrl/devices';
  static const String device = '$baseUrl/devices'; // Notice plural for REST standard
  static const String prediction = '$baseUrl/predictions';
  static const String recommendations = '$baseUrl/recommendations';
  static const String history = '$baseUrl/history';
}
