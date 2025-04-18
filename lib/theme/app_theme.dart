// theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF36D1B6);
  static const Color backgroundColor = Color(0xFF1D1D3B);
  static const Color cardColor = Color(0xFF495888);
  static const Color highRiskColor = Color(0xFFFF5D8F);
  static const Color mediumRiskColor = Color(0xFFF4F4A9);
  static const Color lowRiskColor = Color(0xFF4FECB8);
  static const Color textColor = Colors.white;
  static const Color accentColor = Color(0xFFFFD74A);

  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardTheme(color: cardColor, elevation: 4),
  );
}
