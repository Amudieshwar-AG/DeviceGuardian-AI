import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
}
