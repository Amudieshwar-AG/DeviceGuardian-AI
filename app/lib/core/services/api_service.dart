import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/device.dart';
import '../../models/prediction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      print('API Error (getDevice): $e. Querying Supabase fallback...');
      try {
        final res = await Supabase.instance.client
            .from('telemetry')
            .select('*')
            .eq('device_uuid', id)
            .maybeSingle();
            
        if (res != null) {
          final payload = res['payload'] is String 
              ? jsonDecode(res['payload']) as Map<String, dynamic>
              : Map<String, dynamic>.from(res['payload']);
              
          final systemMap = payload['system'] is Map ? Map<String, dynamic>.from(payload['system']) : {};
          final batteryMap = payload['battery'] is Map ? Map<String, dynamic>.from(payload['battery']) : {};
          final int batteryLevel = (batteryMap['level'] ?? batteryMap['percentage'] ?? 100).toInt();
          final bool isCharging = batteryMap['is_charging'] ?? batteryMap['charging'] ?? false;

          final cpuMap = payload['cpu'] is Map ? Map<String, dynamic>.from(payload['cpu']) : {};
          final double cpuUsage = (cpuMap['usage_percent'] ?? 20.0).toDouble();
          final double temperature = (cpuMap['temperature_c'] ?? cpuMap['gpu_temperature_c'] ?? 35.0).toDouble();

          final storageMap = payload['storage'] is Map ? Map<String, dynamic>.from(payload['storage']) : {};
          final double ssdUsage = (storageMap['usage_percent'] ?? storageMap['disk_usage_percent'] ?? 50.0).toDouble();

          final memoryMap = payload['memory'] is Map ? Map<String, dynamic>.from(payload['memory']) : {};
          final double ramUsage = (memoryMap['usage_percent'] ?? memoryMap['ram_usage_percent'] ?? 50.0).toDouble();

          final healthPred = payload['health_prediction'] is Map ? Map<String, dynamic>.from(payload['health_prediction']) : {};
          final double rul = (payload['native_remaining_useful_life_months'] ?? healthPred['remaining_useful_life_months'] ?? 36.0).toDouble();
          
          int healthScore = (80 + 20 * (rul / 36.0)).round();
          final nativeHealth = payload['native_battery_health_percentage'];
          if (nativeHealth != null) {
            healthScore = (nativeHealth as num).toInt();
          }
          if (healthScore > 100) healthScore = 100;
          if (healthScore < 0) healthScore = 0;

          String statusStr = 'healthy';
          if (healthScore < 75) statusStr = 'critical';
          else if (healthScore < 85) statusStr = 'warning';

          String osVersion = (systemMap['windows_version'] ?? systemMap['device_name'] ?? '').toString().toLowerCase();
          String typeStr = (osVersion.contains('windows') || osVersion.contains('lap') || osVersion.contains('ashwin')) ? 'laptop' : 'phone';

          return Device.fromJson({
            'id': id,
            'name': res['device_name'] ?? 'My Device',
            'type': typeStr,
            'healthScore': healthScore,
            'batteryLevel': batteryLevel,
            'temperature': temperature,
            'cpuUsage': cpuUsage,
            'ramUsage': ramUsage,
            'ssdUsage': ssdUsage,
            'status': statusStr,
            'isCharging': isCharging,
            'lastSynced': res['updated_at'] ?? DateTime.now().toIso8601String(),
            'components': payload,
          });
        }
      } catch (err) {
        print("Supabase getDevice fallback failed: $err");
      }
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
      print('API Error (getPrediction): $e. Querying Supabase fallback...');
      try {
        final res = await Supabase.instance.client
            .from('telemetry')
            .select('payload')
            .eq('device_uuid', id)
            .maybeSingle();
            
        if (res != null && res['payload'] != null) {
          final payload = res['payload'] is String 
              ? jsonDecode(res['payload']) as Map<String, dynamic>
              : Map<String, dynamic>.from(res['payload']);
              
          final healthPred = payload['health_prediction'] as Map<String, dynamic>?;
          if (healthPred != null) {
            final List<ActionableRecommendation> recs = [];
            final explanations = healthPred['explanations'] as List?;
            if (explanations != null) {
              for (var ex in explanations) {
                recs.add(ActionableRecommendation(
                  title: ex.toString(),
                  description: 'Action suggested by AI pipeline.',
                  improvement: '+5%',
                  icon: 'shield',
                  color: 'warning',
                ));
              }
            }

            final cpuMap = payload['cpu'] is Map ? Map<String, dynamic>.from(payload['cpu']) : {};
            final storageMap = payload['storage'] is Map ? Map<String, dynamic>.from(payload['storage']) : {};
            final memoryMap = payload['memory'] is Map ? Map<String, dynamic>.from(payload['memory']) : {};

            final double tempVal = (cpuMap['temperature_c'] ?? cpuMap['gpu_temperature_c'] ?? 35.0).toDouble();
            final double storageVal = (storageMap['usage_percent'] ?? storageMap['disk_usage_percent'] ?? 0.0).toDouble();
            final double cpuVal = (cpuMap['usage_percent'] ?? 0.0).toDouble();
            final double ramVal = (memoryMap['usage_percent'] ?? memoryMap['ram_usage_percent'] ?? 0.0).toDouble();

            double baseHealth = (healthPred['health'] ?? 100.0).toDouble();
            final nativeHealth = payload['native_battery_health_percentage'];
            if (nativeHealth != null) {
              baseHealth = (nativeHealth as num).toDouble();
            }

            double deductions = 0.0;
            if (tempVal > 38.0) {
              deductions += (tempVal - 38.0) * 1.5;
            }
            if (tempVal > 42.0) {
              deductions += (tempVal - 42.0) * 1.0;
            }
            if (storageVal > 75.0) {
              deductions += (storageVal - 75.0) * 0.4;
            }
            if (cpuVal > 80.0) {
              deductions += (cpuVal - 80.0) * 0.2;
            }
            if (ramVal > 80.0) {
              deductions += (ramVal - 80.0) * 0.3;
            }

            final int healthScore = (baseHealth - deductions).round().clamp(0, 100);

            final rul = (payload['native_remaining_useful_life_months'] ?? healthPred['remaining_useful_life_months'] ?? 36.0).toDouble();

            return Prediction(
              deviceId: id,
              healthScore: healthScore,
              riskLevel: (healthPred['risk'] ?? 'Low').toString() + (healthPred['risk'].toString().toLowerCase().contains('risk') ? '' : ' Risk'),
              recommendations: recs,
              shapValues: Map<String, dynamic>.from(healthPred['shap_contributions'] ?? {}),
              isAnomaly: healthPred['is_anomaly'] ?? false,
              anomalyScore: (healthPred['anomaly_score'] ?? 0.0).toDouble(),
              confidenceLevel: (healthPred['confidence_level'] ?? 98.5).toDouble(),
              remainingUsefulLife: rul,
            );
          }
        }
      } catch (err) {
        print("Supabase prediction fallback failed: $err");
      }
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

  /// Send diagnostics ticket to customer support
  Future<Map<String, dynamic>?> sendSupportTicket({
    required String deviceId,
    required int healthScore,
    required String riskLevel,
    required double cpu,
    required double ram,
    required double battery,
    required double temperature,
    required double ssd,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/support/ticket'),
        headers: _headers,
        body: json.encode({
          'deviceId': deviceId,
          'healthScore': healthScore,
          'riskLevel': riskLevel,
          'cpu': cpu,
          'ram': ram,
          'battery': battery,
          'temperature': temperature,
          'ssd': ssd,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to send support ticket: ${response.body}');
        return null;
      }
    } catch (e) {
      print('API Error (sendSupportTicket): $e');
      return null;
    }
  }
}
