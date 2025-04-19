import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF7C4DFF);
  static const Color backgroundColor = Colors.black;
  static const Color cardColor = Color(0xFF1E1E2D);
  static const Color highRiskColor = Color(0xFFFF5D8F);
  static const Color mediumRiskColor = Color(0xFFFFD166);
  static const Color lowRiskColor = Color(0xFF8667D8);
  static const Color textColor = Colors.white;

  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
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
