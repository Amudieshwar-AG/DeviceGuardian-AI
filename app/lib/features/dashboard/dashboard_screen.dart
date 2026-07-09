import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/health_gauge.dart';
import '../../widgets/simple_line_chart.dart';
import '../../models/device.dart';
import '../../models/prediction.dart';
import '../../core/services/api_service.dart';

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
                  child: HealthGauge(score: _prediction?.healthScore ?? _displayDevice.healthScore, size: 260)
                      .animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 32),
                
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
                    
                    _buildMetricCard(context, 'Risk Level', _prediction?.riskLevel ?? 'Unknown', PhosphorIcons.shieldCheck(), _prediction?.riskLevel == 'High Risk' ? AppTheme.critical : AppTheme.success),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 32),
                Text('AI Insights (Why?)', style: Theme.of(context).textTheme.titleLarge)
                    .animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 16),
                
                _buildAIInsights(context).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

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
                    color: _prediction!.riskLevel == 'High Risk' ? AppTheme.critical : AppTheme.success,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (_prediction!.riskLevel == 'High Risk' ? AppTheme.critical : AppTheme.success).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_prediction!.healthScore}%', 
                  style: TextStyle(
                    color: _prediction!.riskLevel == 'High Risk' ? AppTheme.critical : AppTheme.success, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'SHAP Contribution Breakdown:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          
          if (shapKeys.isEmpty)
             Text('Not enough data to calculate SHAP values.', style: TextStyle(color: AppTheme.textSecondary)),
             
          for (var key in shapKeys)
            _buildShapBar(
              context, 
              key.toUpperCase(), 
              (_prediction!.shapValues[key] as num).toDouble(), 
              (_prediction!.shapValues[key] as num).toDouble() > 0.2 ? AppTheme.warning : AppTheme.success
            ),
            
          const SizedBox(height: 16),
          Text(
            'Recommendation: ${_prediction!.recommendations.isNotEmpty ? _prediction!.recommendations.first : "Everything looks good!"}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildShapBar(BuildContext context, String label, double percentage, Color color) {
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
                value: percentage,
                backgroundColor: Theme.of(context).cardColor.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(percentage * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
