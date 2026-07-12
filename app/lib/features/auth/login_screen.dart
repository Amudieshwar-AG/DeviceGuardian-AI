import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _isLogin = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ── DEMO MODE BYPASS (works even when Supabase is down) ──────────────
      final inputId = _emailController.text.trim().toLowerCase();
      final inputPw = _passwordController.text;
      if ((inputId == 'demo' || inputId == 'demo@demo.com') && inputPw == 'demo123') {
        final prefs = await SharedPreferences.getInstance();
        String? myUuid = prefs.getString('official_device_uuid');
        if (myUuid == null) {
          myUuid = const Uuid().v4();
          await prefs.setString('official_device_uuid', myUuid);
        }
        if (mounted) context.go('/home');
        return;
      }
      // ─────────────────────────────────────────────────────────────────────

      if (_isLogin) {
        String loginIdentifier = _emailController.text.trim();
        String actualEmail = loginIdentifier;
        final prefs = await SharedPreferences.getInstance();
        
        if (!loginIdentifier.contains('@')) {
          final mappedEmail = prefs.getString('username_map_$loginIdentifier');
          if (mappedEmail != null) {
            actualEmail = mappedEmail;
          } else {
            try {
              final res = await Supabase.instance.client
                  .from('device_mappings')
                  .select('device_uuid')
                  .eq('username', loginIdentifier)
                  .like('device_uuid', 'email_map:%')
                  .maybeSingle();

              if (res != null && res['device_uuid'] != null) {
                final mapped = res['device_uuid'] as String;
                actualEmail = mapped.replaceFirst('email_map:', '');
                await prefs.setString('username_map_$loginIdentifier', actualEmail);
              } else {
                throw Exception("Username not found. Please log in with your Email.");
              }
            } catch (e) {
              throw Exception("Username not found. Please log in with your Email.");
            }
          }
        }
        
        await Supabase.instance.client.auth.signInWithPassword(
          email: actualEmail,
          password: _passwordController.text,
        );
        
        // Ensure the phone has a unique device UUID
        String? myUuid = prefs.getString('official_device_uuid');
        if (myUuid == null) {
          myUuid = const Uuid().v4();
          await prefs.setString('official_device_uuid', myUuid);
        }

        // Register this device mapping in Supabase if not already mapped
        try {
          final mapping = await Supabase.instance.client
              .from('device_mappings')
              .select('id')
              .eq('username', actualEmail)
              .eq('device_uuid', myUuid)
              .maybeSingle();
              
          if (mapping == null) {
            await Supabase.instance.client.from('device_mappings').insert({
              'username': actualEmail,
              'device_uuid': myUuid,
            });
          }
        } catch (e) {
          debugPrint('Error handling device mapping: $e');
        }
        
        if (_rememberMe) {
          await prefs.setString('saved_email', loginIdentifier);
        } else {
          await prefs.remove('saved_email');
        }
        
        if (mounted) {
          context.go('/home');
        }
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception("Passwords do not match");
        }
        String emailToUse = _emailController.text.trim();
        String usernameToUse = _usernameController.text.trim();
        
        await Supabase.instance.client.auth.signUp(
          email: emailToUse,
          password: _passwordController.text,
          data: {'username': usernameToUse},
        );
        
        // Register the device mapping
        final newDeviceUuid = const Uuid().v4();
        try {
          await Supabase.instance.client.from('device_mappings').insert({
            'username': emailToUse,
            'device_uuid': newDeviceUuid,
          });
        } catch (e) {
          debugPrint('Error inserting device mapping: $e');
        }
        
        // Save mapping locally so they can log in with username later on this device
        final prefs = await SharedPreferences.getInstance();
        if (usernameToUse.isNotEmpty) {
          await prefs.setString('username_map_$usernameToUse', emailToUse);
          try {
            await Supabase.instance.client.from('device_mappings').insert({
              'username': usernameToUse,
              'device_uuid': 'email_map:$emailToUse',
            });
          } catch (e) {
            debugPrint('Error inserting username mapping to Supabase: $e');
          }
        }
        await prefs.setString('official_device_uuid', newDeviceUuid);
        
        // Supabase auto-logs in on sign up if email confirmation is off.
        // We log them out immediately to force manual login.
        await Supabase.instance.client.auth.signOut();
        
        if (mounted) {
          setState(() {
            _isLogin = true;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please sign in."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: Theme.of(context).textTheme.displaySmall,
                  ).animate().slideX(begin: -0.2, end: 0, delay: 100.ms).fadeIn(),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _isLogin ? 'Sign in to monitor your devices.' : 'Sign up to get started.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ).animate().slideX(begin: -0.2, end: 0, delay: 200.ms).fadeIn(),
                  
                  const SizedBox(height: 48),
                  
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          _buildTextField(
                            hint: 'Username',
                            icon: PhosphorIcons.user(),
                            controller: _usernameController,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(
                          hint: _isLogin ? 'Email or Username' : 'Email',
                          icon: PhosphorIcons.envelopeSimple(),
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hint: 'Password',
                          icon: PhosphorIcons.lockKey(),
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            hint: 'Rewrite Password',
                            icon: PhosphorIcons.lockKey(),
                            isPassword: true,
                            controller: _confirmPasswordController,
                          ),
                        ],
                        
                        if (_isLogin) ...[
                          const SizedBox(height: 16),
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
                        ] else
                          const SizedBox(height: 24),
                        
                        if (_isLogin)
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
                            onPressed: _isLoading ? null : _authenticate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: _isLoading 
                                ? const SizedBox(
                                    height: 20, 
                                    width: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, end: 0, delay: 300.ms).fadeIn(),
                  
                  const SizedBox(height: 32),
                  
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Create one"
                            : "Already have an account? Sign In",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
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
