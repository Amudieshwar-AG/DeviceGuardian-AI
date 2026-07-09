import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Icon(PhosphorIcons.brain(), size: 64, color: AppTheme.primaryColor),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack)
               .shimmer(duration: 2.seconds),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Why did AI predict this?',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'Our models analyze millions of telemetry data points to identify degradation patterns. Here is what is contributing to your current health score.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 40),
            
            Text(
              'SHAP Feature Contribution',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 24),
            
            _buildContributionBar(context, 'Battery Wear', 32, AppTheme.critical, 500),
            const SizedBox(height: 20),
            _buildContributionBar(context, 'CPU Temperature', 25, AppTheme.warning, 600),
            const SizedBox(height: 20),
            _buildContributionBar(context, 'SSD Errors', 18, AppTheme.success, 700),
            const SizedBox(height: 20),
            _buildContributionBar(context, 'Fan Speed Variance', 12, AppTheme.success, 800),
            const SizedBox(height: 20),
            _buildContributionBar(context, 'RAM Thrashing', 8, AppTheme.success, 900),
            
            const SizedBox(height: 48),
            
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.lightbulb(), color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Recommendation', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your battery is showing signs of accelerated wear due to frequent deep discharges. Consider keeping your device plugged in when possible or enabling smart charging limits.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/recommendations');
                      },
                      child: const Text('View All Recommendations'),
                    ),
                  )
                ],
              ),
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionBar(BuildContext context, String label, int percentage, Color color, int delayMs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text('$percentage%', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percentage / 100.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Container(
                      width: constraints.maxWidth * value,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideX(begin: -0.1, end: 0);
  }
}
