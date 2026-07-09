import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'services/telemetry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lonsqhuudhiffjitmcbh.supabase.co',
    anonKey: 'sb_publishable_huLEhuc-J4bal6hQRkPf5w_O16MKv6V',
  );

  runApp(
    const ProviderScope(
      child: DeviceGuardianApp(),
    ),
  );
}

class DeviceGuardianApp extends ConsumerStatefulWidget {
  const DeviceGuardianApp({super.key});

  @override
  ConsumerState<DeviceGuardianApp> createState() => _DeviceGuardianAppState();
}

class _DeviceGuardianAppState extends ConsumerState<DeviceGuardianApp> {
  @override
  void initState() {
    super.initState();
    // Start background telemetry sync if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        ref.read(telemetryServiceProvider).start(intervalSeconds: 30);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'DeviceGuardian AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
