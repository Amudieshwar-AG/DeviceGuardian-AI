import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';

import '../../features/home/home_screen.dart';
import '../../features/devices/my_devices_screen.dart';

import '../../features/devices/add_device_screen.dart';
import '../../features/devices/windows_flow_screen.dart';
import '../../features/devices/android_flow_screen.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/recommendations/recommendations_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/notifications/notifications_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/devices',
        builder: (context, state) => const MyDevicesScreen(),
      ),
      GoRoute(
        path: '/add-device',
        builder: (context, state) => const AddDeviceScreen(),
        routes: [
          GoRoute(
            path: 'windows',
            builder: (context, state) => const WindowsFlowScreen(),
          ),
          GoRoute(
            path: 'android',
            builder: (context, state) => const AndroidFlowScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          // If a device is passed in extra, use it, otherwise pass null or a dummy
          final device = state.extra; 
          return DashboardScreen(device: device);
        },
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/recommendations',
        builder: (context, state) => const RecommendationsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
