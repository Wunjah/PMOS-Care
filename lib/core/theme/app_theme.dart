import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryWellness = Color(0xFF165842); // HSL(162, 70%, 30%)
  static const Color primaryLight = Color(0xFFE5F7F3);    // HSL(162, 40%, 94%)
  static const Color brandActive = Color(0xFF2FB591);     // HSL(162, 60%, 46%)

  static const Color accentMenstrual = Color(0xFFEB505E); // HSL(355, 75%, 62%)
  static const Color accentRoseWash = Color(0xFFFDEBED);  // HSL(355, 80%, 95%)

  static const Color glycemicLow = Color(0xFF3AA662);     // Green
  static const Color glycemicMedium = Color(0xFFE69119);  // Amber
  static const Color glycemicHigh = Color(0xFFD93644);    // Red

  static const Color bgDark = Color(0xFF14171A);          // Slate
  static const Color bgLight = Color(0xFFF7F9FB);         // Soft Wash
  static const Color cardDark = Color(0xFF1D2226);        // Charcoal
  static const Color textDark = Color(0xFF1D2226);
  static const Color textLight = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryWellness,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryWellness,
        secondary: brandActive,
        tertiary: accentMenstrual,
        surface: Colors.white,
        error: glycemicHigh,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.5, color: textDark),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4, color: Colors.grey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryWellness,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryWellness,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryWellness,
        secondary: brandActive,
        tertiary: accentMenstrual,
        surface: cardDark,
        error: glycemicHigh,
      ),
      cardTheme: const CardThemeData(
        color: cardDark,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontSize: 32, fontWeight: FontWeight.bold, color: textLight),
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold, color: textLight),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: textLight),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.5, color: textLight),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4, color: Colors.grey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryWellness,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
