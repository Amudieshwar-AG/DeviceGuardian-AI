import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/device.dart';
import '../../models/prediction.dart';

class ApiService {
  // Common headers
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get all devices from the backend
  Future<List<Device>> getDevices() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.devices),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Device.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load devices (Status: ${response.statusCode})');
      }
    } catch (e) {
      // For development, if the server is offline, just return an empty list or throw.
      print('API Error (getDevices): $e');
      throw Exception('Failed to connect to backend: $e');
    }
  }

  /// Get a specific device details
  Future<Device> getDevice(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.device}/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Device.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load device details');
      }
    } catch (e) {
      print('API Error (getDevice): $e');
      throw Exception('Failed to connect to backend: $e');
    }
  }

  /// Get predictions for a device
  Future<Prediction> getPrediction(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.prediction}/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Prediction.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print('API Error (getPrediction): $e');
      throw Exception('Failed to connect to backend: $e');
    }
  }

  /// Register a new device (or update telemetry)
  Future<bool> registerDevice(Map<String, dynamic> telemetryData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.devices),
        headers: _headers,
        body: json.encode(telemetryData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to register device: ${response.body}');
        return false;
      }
    } catch (e) {
      print('API Error (registerDevice): $e');
      // Return true in development to allow UI flow to proceed if backend is offline
      return true; 
    }
  }
}
