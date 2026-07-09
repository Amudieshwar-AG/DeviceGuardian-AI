import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFF4C430); // Gold
  static const Color backgroundColor = Color(0xFF0B0D10);
  static const Color cardColor = Color(0xFF161A20);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;

  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color critical = Colors.red;

  // BorderRadius
  static const double borderRadius = 20.0;
  static const double padding = 20.0;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        background: backgroundColor,
        surface: cardColor,
        error: critical,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displaySmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineSmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleSmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: const TextStyle(color: textPrimary),
          bodyMedium: const TextStyle(color: textPrimary),
          bodySmall: const TextStyle(color: textSecondary),
          labelLarge: const TextStyle(color: textPrimary),
          labelMedium: const TextStyle(color: textSecondary),
          labelSmall: const TextStyle(color: textSecondary),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor, // Dark text on gold button
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Light grey background
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        background: Color(0xFFF5F7FA),
        surface: Colors.white, // White cards
        error: critical,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          displayMedium: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          displaySmall: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          headlineLarge: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          headlineSmall: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          titleSmall: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          bodyLarge: const TextStyle(color: Colors.black87),
          bodyMedium: const TextStyle(color: Colors.black87),
          bodySmall: const TextStyle(color: Colors.black54),
          labelLarge: const TextStyle(color: Colors.black87),
          labelMedium: const TextStyle(color: Colors.black54),
          labelSmall: const TextStyle(color: Colors.black54),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}

// Provide a way to toggle the theme across the app
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void toggle(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
