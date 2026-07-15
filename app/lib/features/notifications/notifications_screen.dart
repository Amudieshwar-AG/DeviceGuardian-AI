import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../core/services/api_service.dart';
import '../../services/device_service.dart';
import '../../models/prediction.dart';
import '../../models/device.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Widget> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final List<Device> devices = await deviceService.getMyDevices();
      List<Widget> notifs = [];
      
      for (Device device in devices) {
        try {
          final Prediction pred = await _apiService.getPrediction(device.id);
          
          if (!mounted) return;
          final risk = pred.riskLevel.toLowerCase();
          
          if (risk.contains('high') || risk.contains('critical')) {
             notifs.add(_buildNotificationItem(
               context,
               'Critical Risk Detected',
               '${device.name} is at High Risk. Immediate action recommended.',
               AppTheme.critical,
               PhosphorIcons.warning(),
               true
             ));
          } else if (risk.contains('medium') || risk.contains('warning')) {
             notifs.add(_buildNotificationItem(
               context,
               'Wear Detected',
               '${device.name} is showing moderate wear. Check recommendations.',
               AppTheme.warning,
               PhosphorIcons.warningCircle(),
               true
             ));
          }
        } catch (e) {
          print("Failed to get prediction for device ${device.id}");
        }
      }
      
      if (mounted) {
        setState(() {
          _notifications = notifs;
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
        title: const Text('Notifications'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                if (_notifications.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Text("No critical notifications at this time.", style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  )
                else
                  _buildNotificationGroup(context, 'Recent Alerts', _notifications, 100),
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
