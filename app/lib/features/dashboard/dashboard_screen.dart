import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/health_gauge.dart';
import '../../widgets/simple_line_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lenovo IdeaPad Slim 5'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.dotsThreeVertical()),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const HealthGauge(score: 94, size: 260)
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
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(context, 'Battery', '91%', PhosphorIcons.batteryHigh(), AppTheme.success),
                _buildMetricCard(context, 'CPU Temp', '43°C', PhosphorIcons.thermometer(), AppTheme.success),
                _buildMetricCard(context, 'SSD', 'Healthy', PhosphorIcons.hardDrives(), AppTheme.success),
                _buildMetricCard(context, 'RAM', '12GB Free', PhosphorIcons.memory(), AppTheme.success),
                _buildMetricCard(context, 'Fan Speed', '2200 RPM', PhosphorIcons.fan(), AppTheme.warning),
                _buildMetricCard(context, 'Risk Level', 'Low', PhosphorIcons.shieldCheck(), AppTheme.success),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.textSecondary),
              Container(
                width: 12,
                height: 12,
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
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          )
        ],
      ),
    );
  }
}
