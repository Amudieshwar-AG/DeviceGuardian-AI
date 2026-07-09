import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AndroidFlowScreen extends StatefulWidget {
  const AndroidFlowScreen({super.key});

  @override
  State<AndroidFlowScreen> createState() => _AndroidFlowScreenState();
}

class _AndroidFlowScreenState extends State<AndroidFlowScreen> {
  final Map<String, bool> _permissions = {
    'Battery': false,
    'Storage': false,
    'Usage Stats': false,
    'Notifications': false,
  };

  bool get _allGranted => _permissions.values.every((v) => v);

  void _togglePermission(String key) {
    setState(() {
      _permissions[key] = !_permissions[key]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Android'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Required Permissions', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'DeviceGuardian needs these permissions to monitor your phone\'s health effectively.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: ListView(
                children: [
                  _buildPermissionCard('Battery', PhosphorIcons.batteryFull(), 'To monitor battery degradation'),
                  const SizedBox(height: 16),
                  _buildPermissionCard('Storage', PhosphorIcons.hardDrives(), 'To check for disk errors'),
                  const SizedBox(height: 16),
                  _buildPermissionCard('Usage Stats', PhosphorIcons.chartBar(), 'To analyze CPU/RAM trends'),
                  const SizedBox(height: 16),
                  _buildPermissionCard('Notifications', PhosphorIcons.bell(), 'To alert you of critical issues'),
                ],
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allGranted ? () {
                  // Simulate registration
                  context.go('/home');
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allGranted ? AppTheme.primaryColor : AppTheme.cardColor,
                ),
                child: const Text('Register Device'),
              ),
            ).animate(target: _allGranted ? 1 : 0).shimmer(duration: 1.seconds),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(String title, IconData icon, String subtitle) {
    final isGranted = _permissions[title]!;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? AppTheme.success.withOpacity(0.2) : AppTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isGranted ? AppTheme.success : AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: isGranted,
            onChanged: (val) => _togglePermission(title),
            activeColor: AppTheme.success,
            activeTrackColor: AppTheme.success.withOpacity(0.3),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
