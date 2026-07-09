import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
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
            Text(
              'Preventive Actions',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              'Complete these tasks to improve your device health score and extend its lifespan.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 32),
            
            _buildRecommendationCard(
              context,
              'Avoid Overnight Charging',
              'Leaving your device plugged in at 100% accelerates battery degradation.',
              '+8%',
              PhosphorIcons.batteryWarning(),
              AppTheme.warning,
              200,
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Clean Cooling Fan',
              'High temperatures detected. Cleaning dust from vents can reduce thermal throttling.',
              '+15%',
              PhosphorIcons.fan(),
              AppTheme.critical,
              300,
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Backup SSD Data',
              'Minor read errors detected. It is highly recommended to backup important files now.',
              '+0%',
              PhosphorIcons.hardDrive(),
              AppTheme.primaryColor,
              400,
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Reduce Heavy Gaming',
              'Sustained high temperatures are degrading components faster than normal.',
              '+5%',
              PhosphorIcons.gameController(),
              AppTheme.warning,
              500,
            ),
            
            const SizedBox(height: 48),
            
            Center(
              child: Text(
                'All caught up!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String title, String description, String improvement, IconData icon, Color iconColor, int delayMs) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.trendUp(), color: AppTheme.success, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Estimated Improvement: $improvement',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideX(begin: 0.1, end: 0);
  }
}
