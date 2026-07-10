import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../core/services/api_service.dart';
import '../../models/prediction.dart';
import '../../services/device_service.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<ActionableRecommendation> _allRecommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final devices = await _apiService.getDevices();
      List<ActionableRecommendation> recs = [];
      
      for (var device in devices) {
        try {
          final pred = await _apiService.getPrediction(device.id);
          recs.addAll(pred.recommendations);
        } catch (e) {
          print("Failed to get prediction for device ${device.id}");
        }
      }
      
      if (mounted) {
        setState(() {
          _allRecommendations = recs;
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

  IconData _getIconForString(String iconName) {
    if (iconName.contains('battery')) return PhosphorIcons.batteryWarning();
    if (iconName.contains('fan')) return PhosphorIcons.fan();
    if (iconName.contains('hard-drive')) return PhosphorIcons.hardDrive();
    if (iconName.contains('game')) return PhosphorIcons.gameController();
    if (iconName.contains('memory')) return PhosphorIcons.memory();
    if (iconName.contains('trash')) return PhosphorIcons.trash();
    if (iconName.contains('check')) return PhosphorIcons.checkCircle();
    return PhosphorIcons.warningCircle();
  }

  Color _getColorForString(String colorName) {
    if (colorName == 'critical') return AppTheme.critical;
    if (colorName == 'warning') return AppTheme.warning;
    if (colorName == 'success') return AppTheme.success;
    return AppTheme.primaryColor;
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
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
                      
                      if (_allRecommendations.isEmpty)
                        Center(
                          child: Text(
                            'All caught up!',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ).animate().fadeIn(delay: 300.ms)
                      else
                        ..._allRecommendations.asMap().entries.map((entry) {
                          int idx = entry.key;
                          ActionableRecommendation rec = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildRecommendationCard(
                              context,
                              rec.title,
                              rec.description,
                              rec.improvement,
                              _getIconForString(rec.icon),
                              _getColorForString(rec.color),
                              200 + (idx * 100),
                            ),
                          );
                        }).toList(),
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
