import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'services/telemetry_service.dart';

import 'services/device_service.dart';
import 'services/notification_service.dart';
import 'models/device.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keys are injected at build time via --dart-define for release builds.
  // Fallback values are used for local development.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw FlutterError(
      'Supabase URL and Key must be provided via --dart-define-from-file=.env\n'
      'Run the project using: flutter run --dart-define-from-file=.env'
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
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
    // Start background telemetry — works with both Supabase session and offline UUID
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null) {
        // Online mode: full Supabase session
        ref.read(telemetryServiceProvider).start(intervalSeconds: 20);
      } else {
        // Offline mode: check if we have a locally saved device UUID
        final prefs = await SharedPreferences.getInstance();
        final localUuid = prefs.getString('official_device_uuid');
        if (localUuid != null) {
          ref.read(telemetryServiceProvider).start(intervalSeconds: 20);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Listen to myDevicesProvider to push native OS notifications when status becomes critical/warning
    ref.listen<AsyncValue<List<Device>>>(myDevicesProvider, (previous, next) {
      next.whenData((devices) {
        ref.read(appNotificationServiceProvider).processDeviceUpdates(devices);
      });
    });

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
