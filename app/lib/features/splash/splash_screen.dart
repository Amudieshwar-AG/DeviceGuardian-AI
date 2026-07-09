import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Particles (Simulated with random glowing dots)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _ParticlePainter(),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 3.seconds, color: AppTheme.primaryColor.withOpacity(0.5)),
           
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ]
                  ),
                  child: Icon(
                    PhosphorIcons.cpu(),
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ).animate()
                 .scale(duration: 800.ms, curve: Curves.easeOutBack)
                 .then()
                 .shimmer(duration: 1.seconds, color: Colors.white),
                
                const SizedBox(height: 32),
                
                Text(
                  'DeviceGuardian AI',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ).animate()
                 .fadeIn(delay: 500.ms, duration: 800.ms)
                 .slideY(begin: 0.2, end: 0),
                 
                const SizedBox(height: 12),
                
                Text(
                  'Predict device failures before they happen.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ).animate()
                 .fadeIn(delay: 1000.ms, duration: 800.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primaryColor;
    // Just a static pattern for the example
    final points = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.6),
    ];
    
    for (var point in points) {
      canvas.drawCircle(point, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
