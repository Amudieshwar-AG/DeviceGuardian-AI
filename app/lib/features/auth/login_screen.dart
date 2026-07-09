import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Illustration / Gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 1.seconds),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  Icon(
                    PhosphorIcons.cpu(),
                    size: 48,
                    color: AppTheme.primaryColor,
                  ).animate().slideX(begin: -0.2, end: 0).fadeIn(),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall,
                  ).animate().slideX(begin: -0.2, end: 0, delay: 100.ms).fadeIn(),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Sign in to monitor your devices.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ).animate().slideX(begin: -0.2, end: 0, delay: 200.ms).fadeIn(),
                  
                  const SizedBox(height: 48),
                  
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildTextField(
                          hint: 'Email',
                          icon: PhosphorIcons.envelopeSimple(),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hint: 'Password',
                          icon: PhosphorIcons.lockKey(),
                          isPassword: true,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryColor,
                                  checkColor: AppTheme.backgroundColor,
                                ),
                                Text('Remember me', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Gradient Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF4C430), Color(0xFFD4A010)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              context.go('/home');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, end: 0, delay: 300.ms).fadeIn(),
                  
                  const SizedBox(height: 32),
                  
                  Center(
                    child: Text('OR', style: Theme.of(context).textTheme.bodySmall),
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/home');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        ),
                      ),
                      icon: Icon(PhosphorIcons.googleLogo(), color: Colors.white),
                      label: const Text('Continue with Google', style: TextStyle(color: Colors.white)),
                    ),
                  ).animate().slideY(begin: 0.2, end: 0, delay: 600.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}
