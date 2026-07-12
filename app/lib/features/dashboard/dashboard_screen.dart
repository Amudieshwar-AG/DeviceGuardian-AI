import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/health_gauge.dart';
import '../../widgets/simple_line_chart.dart';
import '../../models/device.dart';
import '../../models/prediction.dart';
import '../../core/services/api_service.dart';
import '../../services/telemetry_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final dynamic device; // passed from router
  
  const DashboardScreen({super.key, this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Prediction? _prediction;
  bool _isLoading = true;
  String? _error;
  bool _isShapExpanded = false;
  bool _isSubmittingTicket = false;
  
  // Fallback for null devices
  late Device _displayDevice;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.device != null && widget.device is Device) {
      _displayDevice = widget.device;
    } else {
      _displayDevice = Device(
        id: 'unknown',
        name: 'Unknown Device',
        type: DeviceType.laptop,
        healthScore: 0,
        batteryLevel: 0,
        temperature: 0,
        cpuUsage: 0,
        ramUsage: 0,
        ssdUsage: 0,
        status: DeviceStatus.warning,
        isCharging: false,
        lastSynced: 'Never',
        components: {},
      );
    }
    _loadData();
    
    // Auto-refresh every 30 seconds to show real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _showInAppNotification(String title, String body, Color statusColor) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C).withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill), color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: () => entry.remove(),
                ),
              ],
            ),
          ).animate().slideY(begin: -1.0, end: 0.0, duration: 400.ms, curve: Curves.easeOutBack),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    
    // Auto remove after 4 seconds
    Timer(const Duration(seconds: 4), () {
      try {
        entry.remove();
      } catch (_) {}
    });
  }
  
  Future<void> _loadData() async {
    if (_displayDevice.id == 'unknown') {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      // Fetch both device metrics (for real-time temp/battery) and predictions
      final device = await _apiService.getDevice(_displayDevice.id);
      final pred = await _apiService.getPrediction(_displayDevice.id);
      
      if (mounted) {
        setState(() {
          _displayDevice = device;
          _prediction = pred;
          _isLoading = false;
        });

        _showInAppNotification(
          'DeviceGuardian Scan Completed',
          '${device.name} health is ${pred.healthScore}% (${pred.riskLevel}).',
          pred.riskLevel == 'High Risk' ? AppTheme.critical : (pred.riskLevel == 'Medium Risk' ? AppTheme.warning : AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showDiagnosticsReport(BuildContext context) {
    if (_prediction == null) return;
    
    final report = """
========================================
   DEVICEGUARDIAN AI DIAGNOSTICS REPORT
========================================
Generated At: ${DateTime.now().toLocal().toString()}
Device ID: ${_prediction!.deviceId}
Device Name: ${_displayDevice.name}
Device Type: ${_displayDevice.type.toString().split('.').last}
Status: ${_displayDevice.status.toString().split('.').last}

----------------------------------------
HEALTH & RISK ASSESSMENT
----------------------------------------
AI System Health Score: ${_prediction!.healthScore}%
Confidence Level: ${_prediction!.confidenceLevel.toStringAsFixed(1)}%
Risk Classification: ${_prediction!.riskLevel}
Anomaly Flagged: ${_prediction!.isAnomaly ? 'YES' : 'NO'}
Anomaly Score: ${_prediction!.anomalyScore.toStringAsFixed(4)}

----------------------------------------
TELEMETRY METRICS
----------------------------------------
CPU/GPU Temperature: ${_displayDevice.temperature.toStringAsFixed(1)}°C
CPU Load: ${_displayDevice.cpuUsage.toStringAsFixed(1)}%
RAM Usage: ${_displayDevice.ramUsage.toStringAsFixed(1)}%
SSD Storage Used: ${_displayDevice.ssdUsage.toStringAsFixed(1)}%
Battery Level: ${_displayDevice.batteryLevel}%

----------------------------------------
SHAP CONTRIBUTION VALUES
----------------------------------------
${_prediction!.shapValues.entries.map((e) => "• ${e.key.toUpperCase()}: ${e.value.toStringAsFixed(3)}").join('\n')}

----------------------------------------
PREVENTATIVE ACTION SUGGESTIONS
----------------------------------------
${_prediction!.recommendations.map((r) => "[${r.title}]\n${r.description} (Est. Improvement: ${r.improvement})").join('\n\n')}
========================================
""";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(PhosphorIcons.fileText(PhosphorIconsStyle.fill), color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Diagnostics Report', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 350),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                report,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: report));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report copied to clipboard!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
                Navigator.of(context).pop();
              },
              icon: Icon(PhosphorIcons.copy(), size: 16),
              label: const Text('Copy Text'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final url = Uri.parse('${ApiConstants.baseUrl}/api/reports/${_prediction!.deviceId}/docx');
                try {
                  // Direct launch bypasses package visibility queries on modern Android (Android 11+)
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  try {
                    await launchUrl(url);
                  } catch (e2) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open browser: $e2')),
                      );
                    }
                  }
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(PhosphorIcons.downloadSimple(), size: 16),
              label: const Text('Download Word'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCalibrationDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final double currentCalibrated = prefs.getDouble('calibrated_battery_health') ?? 
        (_prediction?.healthScore ?? _displayDevice.healthScore).toDouble();
    
    final controller = TextEditingController(text: currentCalibrated.toInt().toString());
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(PhosphorIcons.wrench(PhosphorIconsStyle.fill), color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Calibrate Battery', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Some manufacturers (like Vivo/iQOO) lock down standard battery capacity APIs.\n\nYou can manually enter your phone\'s actual battery health percentage (from OS settings) to calibrate the AI model.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Battery Health (%)',
                  labelStyle: const TextStyle(color: AppTheme.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final double? value = double.tryParse(controller.text);
                if (value != null && value > 0 && value <= 100) {
                  final p = await SharedPreferences.getInstance();
                  await p.setDouble('calibrated_battery_health', value);
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    
                    // Trigger dynamic sync immediately
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      await ProviderScope.containerOf(context)
                          .read(telemetryServiceProvider)
                          .syncNow();
                      await _loadData();
                    } catch (e) {
                      print("Error syncing telemetry: $e");
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Battery health calibrated successfully!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendSupportTicket(BuildContext context) async {
    if (_prediction == null) return;
    
    setState(() {
      _isSubmittingTicket = true;
    });
    
    try {
      final result = await _apiService.sendSupportTicket(
        deviceId: _prediction!.deviceId,
        healthScore: _prediction!.healthScore,
        riskLevel: _prediction!.riskLevel,
        cpu: _displayDevice.cpuUsage,
        ram: _displayDevice.ramUsage,
        battery: _displayDevice.batteryLevel.toDouble(),
        temperature: _displayDevice.temperature,
        ssd: _displayDevice.ssdUsage,
      );
      
      if (result != null) {
        // Trigger data sync immediately
        await _loadData();
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppTheme.success),
                    const SizedBox(width: 8),
                    const Text('Ticket Submitted', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket ID: ${result['ticketId']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result['message'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit ticket. Please check connection.'),
              backgroundColor: AppTheme.critical,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.critical,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingTicket = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayDevice.name),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowsClockwise()),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      HealthGauge(score: _prediction?.healthScore ?? _displayDevice.healthScore, size: 260)
                          .animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill), color: AppTheme.primaryColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              _prediction != null
                                  ? 'Prediction Confidence: ${_prediction!.confidenceLevel.toStringAsFixed(1)}%'
                                  : 'Prediction Confidence: --',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      if (_displayDevice.type == DeviceType.phone) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showCalibrationDialog(context),
                          icon: Icon(PhosphorIcons.wrench(), size: 14, color: AppTheme.textSecondary),
                          label: Text(
                            'Calibrate Battery Health',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                if (_prediction?.isAnomaly == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.critical.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.critical.withOpacity(0.5), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.warningOctagon(PhosphorIconsStyle.fill), color: AppTheme.critical, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ANOMALY DETECTED',
                                style: TextStyle(color: AppTheme.critical, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Isolation Forest flagged unusual operational metrics (Score: ${_prediction!.anomalyScore.toStringAsFixed(3)}). Keep device cool.',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(duration: 500.ms),
                  const SizedBox(height: 24),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Metrics', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                        context.push('/insights');
                      },
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.brain(), color: AppTheme.primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Text('AI Insights', style: TextStyle(color: AppTheme.primaryColor)),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 16),
                
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _buildMetricCard(
                      context, 
                      'Battery', 
                      _displayDevice.isCharging ? 'Charging • ${_displayDevice.batteryLevel}%' : '${_displayDevice.batteryLevel}%', 
                      _displayDevice.isCharging ? PhosphorIcons.lightning() : PhosphorIcons.batteryHigh(), 
                      _displayDevice.isCharging ? AppTheme.success : (_displayDevice.batteryLevel > 20 ? AppTheme.success : AppTheme.critical)
                    ),
                    
                    if (_displayDevice.temperature > 0)
                      _buildMetricCard(
                        context, 
                        _displayDevice.type == DeviceType.phone ? 'Temp' : 'CPU Temp', 
                        '${_displayDevice.temperature.toStringAsFixed(1)}°C', 
                        PhosphorIcons.thermometer(), 
                        _displayDevice.temperature < 60 ? AppTheme.success : AppTheme.warning
                      )
                    else 
                      _buildMetricCard(
                        context, 
                        _displayDevice.type == DeviceType.phone ? 'Temp' : 'CPU Temp', 
                        'Not Available', 
                        PhosphorIcons.thermometer(), 
                        AppTheme.textSecondary
                      ),
                    
                    if (_displayDevice.type != DeviceType.phone) ...[
                      _buildMetricCard(context, 'SSD Usage', '${_displayDevice.ssdUsage.toStringAsFixed(1)}%', PhosphorIcons.hardDrives(), _displayDevice.ssdUsage < 85 ? AppTheme.success : AppTheme.critical),
                      _buildMetricCard(context, 'RAM Usage', '${_displayDevice.ramUsage.toStringAsFixed(1)}%', PhosphorIcons.memory(), _displayDevice.ramUsage < 80 ? AppTheme.success : AppTheme.warning),
                      _buildMetricCard(context, 'Fan Speed', 'Normal', PhosphorIcons.fan(), AppTheme.success),
                    ] else ...[
                      _buildMetricCard(context, 'Storage', '${_displayDevice.ssdUsage.toStringAsFixed(1)}% Used', PhosphorIcons.hardDrives(), _displayDevice.ssdUsage < 90 ? AppTheme.success : AppTheme.critical),
                      _buildMetricCard(context, 'CPU Usage', '${_displayDevice.cpuUsage.toStringAsFixed(1)}%', PhosphorIcons.cpu(), _displayDevice.cpuUsage < 80 ? AppTheme.success : AppTheme.warning),
                    ],
                    
                    _buildMetricCard(
                       context, 
                       'Risk Level', 
                       _prediction?.riskLevel ?? 'Unknown', 
                       PhosphorIcons.shieldCheck(), 
                       _prediction?.riskLevel == 'High Risk' 
                           ? AppTheme.critical 
                           : (_prediction?.riskLevel == 'Medium Risk' 
                               ? AppTheme.warning 
                               : AppTheme.success)
                     ),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AI Insights (Why?)', style: Theme.of(context).textTheme.titleLarge),
                    if (_prediction != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showDiagnosticsReport(context),
                        icon: Icon(PhosphorIcons.fileText(), size: 16),
                        label: const Text('Generate Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 16),
                
                _buildAIInsights(context).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                if (_prediction != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _displayDevice.status == DeviceStatus.supportContacted
                            ? AppTheme.success.withOpacity(0.15)
                            : (_prediction!.riskLevel == 'High Risk' 
                                ? AppTheme.critical.withOpacity(0.15) 
                                : AppTheme.primaryColor.withOpacity(0.1)),
                        foregroundColor: _displayDevice.status == DeviceStatus.supportContacted
                            ? AppTheme.success
                            : (_prediction!.riskLevel == 'High Risk' 
                                ? AppTheme.critical 
                                : AppTheme.textPrimary),
                        side: BorderSide(
                          color: _displayDevice.status == DeviceStatus.supportContacted
                              ? AppTheme.success.withOpacity(0.5)
                              : (_prediction!.riskLevel == 'High Risk' 
                                  ? AppTheme.critical.withOpacity(0.5) 
                                  : AppTheme.textSecondary.withOpacity(0.2)),
                          width: 1.5
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_isSubmittingTicket || _displayDevice.status == DeviceStatus.supportContacted)
                          ? null 
                          : () => _sendSupportTicket(context),
                      icon: _isSubmittingTicket 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(
                              _displayDevice.status == DeviceStatus.supportContacted 
                                  ? PhosphorIcons.checkCircle() 
                                  : PhosphorIcons.headset(), 
                              size: 20
                            ),
                      label: Text(
                        _displayDevice.status == DeviceStatus.supportContacted
                            ? 'Support Ticket Already Sent' 
                            : 'Send Diagnostics to Customer Support',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                      ),
                    ),
                  ).animate().fadeIn(delay: 410.ms),
                ],

                const SizedBox(height: 32),
                Text('Lifespan & Runtime Prediction', style: Theme.of(context).textTheme.titleLarge)
                    .animate().fadeIn(delay: 420.ms),
                const SizedBox(height: 16),
                _buildLifespanCard(context).animate().fadeIn(delay: 440.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),
                Text('Health Trend', style: Theme.of(context).textTheme.titleLarge)
                    .animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 200,
                  child: GlassCard(
                    padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 24),
                    child: const SimpleLineChart(),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color statusColor) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 20),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAIInsights(BuildContext context) {
    if (_prediction == null) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Text('AI Insights not available.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    
    final shapKeys = _prediction!.shapValues.keys.toList();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.brain(), color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _prediction!.riskLevel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _prediction!.riskLevel == 'High Risk' 
                        ? AppTheme.critical 
                        : (_prediction!.riskLevel == 'Medium Risk' 
                            ? AppTheme.warning 
                            : AppTheme.success),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (_prediction!.riskLevel == 'High Risk' 
                      ? AppTheme.critical 
                      : (_prediction!.riskLevel == 'Medium Risk' 
                          ? AppTheme.warning 
                          : AppTheme.success)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_prediction!.healthScore}%', 
                  style: TextStyle(
                    color: _prediction!.riskLevel == 'High Risk' 
                        ? AppTheme.critical 
                        : (_prediction!.riskLevel == 'Medium Risk' 
                            ? AppTheme.warning 
                            : AppTheme.success), 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'SHAP Breakdown:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isShapExpanded = !_isShapExpanded;
                  });
                },
                child: Row(
                  children: [
                    Text(_isShapExpanded ? 'Show Less' : 'Expand Details', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                    Icon(_isShapExpanded ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(), color: AppTheme.primaryColor, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (shapKeys.isEmpty)
             Text('Not enough data to calculate SHAP values.', style: TextStyle(color: AppTheme.textSecondary)),
             
          for (var key in shapKeys) ...[
            _buildShapBar(
              context, 
              key.toUpperCase(), 
              (_prediction!.shapValues[key] as num).toDouble(), 
              (_prediction!.shapValues[key] as num).toDouble() > 0.2 ? AppTheme.warning : AppTheme.success
            ),
            if (_isShapExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                child: Text(
                  _getShapExplanation(key, (_prediction!.shapValues[key] as num).toDouble()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, height: 1.3),
                ),
              ),
          ],
            
          const SizedBox(height: 16),
          Text(
            'Actionable Recommendations:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_prediction!.recommendations.isEmpty)
            Row(
              children: [
                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text('Everything looks good!', style: Theme.of(context).textTheme.bodyMedium),
              ],
            )
          else
            ..._prediction!.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill), color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec.title, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  String _getShapExplanation(String key, double impact) {
    String impactStr = impact > 0.2 ? 'high negative impact' : 'normal degradation factor';
    if (key.contains('Battery')) {
      return '• Battery Age: Chemical degradation of Li-ion cells. Currently contributing ${(impact * 100).toInt()}% to overall wear. ($impactStr)';
    } else if (key.contains('Thermal')) {
      return '• Thermal Stress: Structural degradation caused by operating temperatures above 40°C. Currently contributing ${(impact * 100).toInt()}% to overall wear. ($impactStr)';
    } else if (key.contains('CPU')) {
      return '• CPU Load: Silicon wear and thermal paste degradation due to high processing loads. Currently contributing ${(impact * 100).toInt()}% to overall wear. ($impactStr)';
    } else if (key.contains('SSD') || key.contains('Storage')) {
      return '• SSD Wear: Wear on storage flash gates due to total bytes written (TBW). Currently contributing ${(impact * 100).toInt()}% to overall wear. ($impactStr)';
    } else if (key.contains('RAM') || key.contains('Swap')) {
      return '• RAM Swap Stress: Wear on storage gates caused by memory paging when RAM is full. Currently contributing ${(impact * 100).toInt()}% to overall wear. ($impactStr)';
    }
    return '• $key: Currently contributing ${(impact * 100).toInt()}% to overall wear.';
  }

  Widget _buildLifespanCard(BuildContext context) {
    final int batteryLevel = _displayDevice.batteryLevel;
    final bool isCharging = _displayDevice.isCharging;
    final bool isLaptop = _displayDevice.type == DeviceType.laptop;
    
    String runtimeText = '';
    if (isCharging) {
      final int minsLeft = ((100 - batteryLevel) * 1.2).round();
      runtimeText = minsLeft <= 0 ? 'Fully Charged' : '$minsLeft mins to full charge';
    } else {
      final double hoursLeft = batteryLevel * 0.12;
      runtimeText = '${hoursLeft.toStringAsFixed(1)} Hours remaining';
    }
    
    final int healthScore = _prediction?.healthScore ?? _displayDevice.healthScore;
    final double remainingMonths = _prediction?.remainingUsefulLife ?? 36.0;
    
    String lifespanText = '${remainingMonths.toStringAsFixed(1)} Months remaining';
    if (healthScore < 60) {
      lifespanText = 'Replace battery immediately';
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!isLaptop) ...[
            Row(
              children: [
                Icon(PhosphorIcons.lightning(), color: AppTheme.success, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Battery Runtime', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        runtimeText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
          ],
          Row(
            children: [
              Icon(PhosphorIcons.hourglassHigh(), color: AppTheme.warning, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Predicted Battery Lifespan', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      lifespanText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapBar(BuildContext context, String label, double percentage, Color color) {
    final double displayValue = percentage.abs().clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: displayValue,
                backgroundColor: Theme.of(context).cardColor.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(displayValue * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
