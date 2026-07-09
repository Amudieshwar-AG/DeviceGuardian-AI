import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class WindowsFlowScreen extends StatefulWidget {
  const WindowsFlowScreen({super.key});

  @override
  State<WindowsFlowScreen> createState() => _WindowsFlowScreenState();
}

class _WindowsFlowScreenState extends State<WindowsFlowScreen> {
  int _step = 0;

  void _nextStep() {
    if (_step < 2) {
      setState(() {
        _step++;
      });
      if (_step == 2) {
        // Simulate waiting for laptop connection
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            context.go('/home'); // Success, go back to home
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Windows'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return KeyedSubtree(key: const ValueKey(0), child: _buildStep1());
      case 1:
        return KeyedSubtree(key: const ValueKey(1), child: _buildStep2());
      case 2:
        return KeyedSubtree(key: const ValueKey(2), child: _buildStep3());
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator(0),
        const SizedBox(height: 32),
        Center(
          child: Icon(PhosphorIcons.laptop(), size: 120, color: AppTheme.primaryColor)
            .animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 32),
        Text('How it works', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        _buildInfoRow(PhosphorIcons.download(), 'Download our lightweight agent'),
        const SizedBox(height: 16),
        _buildInfoRow(PhosphorIcons.shieldCheck(), 'Agent runs in the background'),
        const SizedBox(height: 16),
        _buildInfoRow(PhosphorIcons.chartLineUp(), 'AI predicts issues securely'),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            child: const Text('Continue'),
          ),
        )
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator(1),
        const SizedBox(height: 32),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(PhosphorIcons.fileZip(), size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('DeviceGuardian_Agent.exe', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Size: 4.2 MB', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _nextStep,
                  icon: Icon(PhosphorIcons.downloadSimple(), color: AppTheme.backgroundColor),
                  label: const Text('Download Agent'),
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: 0.1, end: 0),
        const Spacer(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cardColor,
            ),
            child: const CircularProgressIndicator(color: AppTheme.primaryColor),
          ).animate().scale().shimmer(duration: 2.seconds),
        ),
        const SizedBox(height: 32),
        Text('Waiting for laptop...', style: Theme.of(context).textTheme.headlineMedium)
            .animate().fadeIn(),
        const SizedBox(height: 16),
        Text(
          'Please install the downloaded agent and log in. We will detect your connection automatically.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index <= currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 16,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(target: isActive ? 1 : 0).scaleX();
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        )
      ],
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
