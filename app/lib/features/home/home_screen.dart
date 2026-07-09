import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/health_gauge.dart';
import '../../services/device_service.dart';
import '../../services/telemetry_service.dart';
import '../../models/device.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(myDevicesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-device');
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.backgroundColor,
        icon: Icon(PhosphorIcons.plus()),
        label: const Text('Add Device', style: TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // 1. Push latest battery data to backend first
            await ref.read(telemetryServiceProvider).syncNow();
            // 2. Then refresh device list from backend
            ref.invalidate(myDevicesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning,',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Supabase.instance.client.auth.currentUser?.userMetadata?['username'] ?? 'User',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                      
                      GestureDetector(
                        onTap: () {
                          context.push('/profile');
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.cardColor,
                          child: Icon(PhosphorIcons.user(), color: AppTheme.primaryColor),
                        ),
                      ).animate().fadeIn().scale(delay: 100.ms),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search devices or issues...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                        prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Overall Health Score
                  Center(
                    child: devicesAsync.when(
                      data: (devices) {
                        if (devices.isEmpty) return const HealthGauge(score: 0, size: 240);
                        // Calculate average health score of all devices
                        int avgScore = (devices.map((d) => d.healthScore).reduce((a, b) => a + b) / devices.length).round();
                        return HealthGauge(score: avgScore, size: 240)
                            .animate().scale(delay: 300.ms, duration: 600.ms, curve: Curves.easeOutBack);
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const HealthGauge(score: 0, size: 240),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(context, PhosphorIcons.bell(), 'Alerts', () { context.push('/notifications'); }),
                      _buildQuickAction(context, PhosphorIcons.lightning(), 'Optimize', () { context.push('/recommendations'); }),
                      _buildQuickAction(context, PhosphorIcons.clockCounterClockwise(), 'History', () { context.push('/history'); }),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  // Connected Devices
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Connected Devices',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/devices');
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Horizontal Device List
                  SizedBox(
                    height: 180,
                    child: devicesAsync.when(
                      data: (devices) {
                        if (devices.isEmpty) {
                          return const Center(child: Text("No devices found. Add a device to begin tracking."));
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceCard(context, devices[index])
                                .animate().fadeIn(delay: Duration(milliseconds: 600 + (index * 100)))
                                .slideX(begin: 0.1, end: 0);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                  
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, Device device) {
    IconData deviceIcon = device.type == DeviceType.laptop ? PhosphorIcons.laptop() : PhosphorIcons.deviceMobile();
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: GlassCard(
        onTap: () {
          context.push('/dashboard', extra: device);
        },
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(deviceIcon, color: AppTheme.primaryColor, size: 32),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: device.healthScore >= 90 ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${device.healthScore}% Health',
                    style: TextStyle(
                      color: device.healthScore >= 90 ? AppTheme.success : AppTheme.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              device.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(device.isCharging ? PhosphorIcons.lightning() : PhosphorIcons.batteryFull(), size: 16, color: device.isCharging ? AppTheme.success : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(device.isCharging ? 'Charging • ${device.batteryLevel}%' : '${device.batteryLevel}%', style: Theme.of(context).textTheme.bodySmall),
                
                if (device.temperature > 0) ...[
                  const SizedBox(width: 16),
                  Icon(PhosphorIcons.thermometer(), size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${device.temperature.toStringAsFixed(1)}°C', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }
}
