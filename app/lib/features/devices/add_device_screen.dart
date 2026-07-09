import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AddDeviceScreen extends StatelessWidget {
  const AddDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
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
            Text(
              'What would you like to connect?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select the type of device you want to monitor.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            GlassCard(
              onTap: () {
                context.push('/add-device/windows');
              },
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(PhosphorIcons.laptop(), size: 48, color: AppTheme.primaryColor),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Windows Laptop', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Install our lightweight agent', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(PhosphorIcons.caretRight(), color: AppTheme.textSecondary),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            GlassCard(
              onTap: () {
                context.push('/add-device/android');
              },
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(PhosphorIcons.deviceMobile(), size: 48, color: AppTheme.primaryColor),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Android Phone', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Grant telemetry permissions', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(PhosphorIcons.caretRight(), color: AppTheme.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
