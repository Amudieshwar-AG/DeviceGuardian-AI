import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cardColor,
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/300?img=11'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  Text('Alex Morgan', style: Theme.of(context).textTheme.headlineMedium)
                      .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 4),
                  Text('Pro Subscription', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  )).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            _buildSection(context, 'Account', [
              _buildListTile(context, 'Connected Devices', PhosphorIcons.devices(), '2 Active', () {}),
              _buildListTile(context, 'Subscription', PhosphorIcons.creditCard(), 'Manage', () {}),
            ], 300),
            
            const SizedBox(height: 24),
            
            _buildSection(context, 'Preferences', [
              _buildSwitchTile(context, 'Dark Mode', PhosphorIcons.moon(), true),
              _buildSwitchTile(context, 'Notifications', PhosphorIcons.bell(), true),
              _buildListTile(context, 'Language', PhosphorIcons.translate(), 'English', () {}),
            ], 400),
            
            const SizedBox(height: 24),
            
            _buildSection(context, 'Data & Privacy', [
              _buildListTile(context, 'Export Device Report', PhosphorIcons.export(), '', () {}),
              _buildListTile(context, 'Privacy Policy', PhosphorIcons.shieldCheck(), '', () {}),
            ], 500),
            
            const SizedBox(height: 24),
            
            GlassCard(
              onTap: () {
                context.go('/login');
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.signOut(), color: AppTheme.critical),
                  const SizedBox(width: 8),
                  Text('Logout', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.critical)),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children, int delayMs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildListTile(BuildContext context, String title, IconData icon, String trailing, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty) 
            Text(trailing, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          Icon(PhosphorIcons.caretRight(), color: AppTheme.textSecondary, size: 16),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, IconData icon, bool value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Switch(
        value: value,
        onChanged: (val) {},
        activeColor: AppTheme.primaryColor,
        activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
      ),
    );
  }
}
