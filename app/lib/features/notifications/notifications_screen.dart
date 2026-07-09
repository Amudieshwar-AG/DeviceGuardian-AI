import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildNotificationGroup(
            context,
            'Today',
            [
              _buildNotificationItem(
                context,
                'Battery health dropped 5%',
                'Your Lenovo IdeaPad Slim 5 battery health has degraded. Review recommendations.',
                AppTheme.warning,
                PhosphorIcons.batteryWarning(),
                true,
              ),
              _buildNotificationItem(
                context,
                'SSD errors increasing',
                'Minor read errors detected. Please backup your data.',
                AppTheme.critical,
                PhosphorIcons.hardDrive(),
                true,
              ),
            ],
            100,
          ),
          const SizedBox(height: 32),
          _buildNotificationGroup(
            context,
            'Yesterday',
            [
              _buildNotificationItem(
                context,
                'Device overheating',
                'Sustained high temperatures detected during gaming session.',
                AppTheme.warning,
                PhosphorIcons.thermometer(),
                false,
              ),
              _buildNotificationItem(
                context,
                'Weekly scan complete',
                'No new issues found on Samsung Galaxy S24.',
                AppTheme.success,
                PhosphorIcons.checkCircle(),
                false,
              ),
            ],
            300,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationGroup(BuildContext context, String title, List<Widget> items, int delayMs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...items,
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildNotificationItem(BuildContext context, String title, String body, Color color, IconData icon, bool isUnread) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
