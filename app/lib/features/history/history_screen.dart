import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<_TelemetryPoint> _points = [];
  String? _deviceName;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceUuid = prefs.getString('official_device_uuid');
      if (deviceUuid == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch last 48 telemetry rows from Supabase ordered by time
      final response = await Supabase.instance.client
          .from('telemetry')
          .select('payload, updated_at')
          .eq('device_uuid', deviceUuid)
          .order('updated_at', ascending: false)
          .limit(48);

      final rows = (response as List<dynamic>);
      final points = rows.reversed.map((row) {
        final payload = row['payload'] as Map<String, dynamic>? ?? {};
        final battery = payload['battery'] as Map<String, dynamic>? ?? {};
        final batteryPct = (battery['percentage'] as num?)?.toDouble() ?? 
            (payload['battery'] as num?)?.toDouble() ?? 0.0;
        final updatedAt = DateTime.tryParse(row['updated_at'] ?? '') ?? DateTime.now();
        return _TelemetryPoint(battery: batteryPct, timestamp: updatedAt);
      }).toList();

      // Try to get device name
      String? name;
      if (rows.isNotEmpty) {
        final p = rows.first['payload'] as Map<String, dynamic>? ?? {};
        final sys = p['system'] as Map<String, dynamic>? ?? {};
        name = sys['device_name'] as String?;
      }

      if (mounted) {
        setState(() {
          _points = points;
          _deviceName = name;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('History load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_deviceName != null ? '$_deviceName • History' : 'Device History'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowsClockwise()),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadHistory();
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
                  // Stats Row
                  if (_points.isNotEmpty) ...[
                    Row(
                      children: [
                        _buildStatChip('Min', '${_points.map((p) => p.battery).reduce((a, b) => a < b ? a : b).toInt()}%', AppTheme.critical),
                        const SizedBox(width: 12),
                        _buildStatChip('Max', '${_points.map((p) => p.battery).reduce((a, b) => a > b ? a : b).toInt()}%', AppTheme.success),
                        const SizedBox(width: 12),
                        _buildStatChip('Readings', '${_points.length}', AppTheme.primaryColor),
                      ],
                    ).animate().fadeIn(),
                    const SizedBox(height: 24),
                  ],

                  // Battery Chart
                  Text('Battery Level History', style: Theme.of(context).textTheme.titleLarge)
                      .animate().fadeIn(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: GlassCard(
                      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 8, right: 20),
                      child: _points.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.chartLine(), size: 40, color: AppTheme.textSecondary),
                                  const SizedBox(height: 8),
                                  Text('No history yet.\nPull-to-refresh on Home to sync data.', 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                            )
                          : LineChart(_buildChartData()),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),

                  // Timeline
                  Text('Reading Timeline', style: Theme.of(context).textTheme.titleLarge)
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),

                  if (_points.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          'No readings yet. Open the app while your device is connected to start collecting history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._points.reversed.take(12).toList().asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final color = p.battery > 50 ? AppTheme.success : (p.battery > 20 ? AppTheme.warning : AppTheme.critical);
                      return _buildTimelineItem(
                        context,
                        _formatTime(p.timestamp),
                        'Battery: ${p.battery.toInt()}%',
                        color,
                        i == 0,
                        i * 60,
                      );
                    }),
                ],
              ),
            ),
    );
  }

  LineChartData _buildChartData() {
    final spots = _points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.battery);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withOpacity(0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}%',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 9),
            ),
          ),
        ),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppTheme.primaryColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: spots.length <= 10),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.25),
                AppTheme.primaryColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTimelineItem(BuildContext context, String time, String desc, Color color, bool isFirst, int delayMs) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
                  ),
                ),
                Expanded(
                  child: Container(width: 2, color: AppTheme.textSecondary.withOpacity(0.1)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold, color: color,
                  )),
                  const SizedBox(height: 6),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(desc, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideX(begin: 0.1, end: 0);
  }
}

class _TelemetryPoint {
  final double battery;
  final DateTime timestamp;
  const _TelemetryPoint({required this.battery, required this.timestamp});
}


