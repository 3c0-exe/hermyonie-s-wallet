import 'package:flutter/material.dart';

class PesowiseColors {
  static const background = Color(0xFFFCF8FA);
  static const blushCard = Color(0xFFF6E4EC);
  static const blushBorder = Color(0xFFEADDE3);
  static const chipBg = Color(0xFFF6EDF1);
  static const accent = Color(0xFFE8B2C8);
  static const strong = Color(0xFF8E3659);
  static const muted = Color(0xFF756571);
  static const white = Colors.white;
  static const ink = Color(0xFF30232B);
  static const green = Color(0xFF26705A);
}

class PesowiseTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PesowiseColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PesowiseColors.strong,
      surface: Colors.white,
    ),
    fontFamily: 'sans-serif',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: PesowiseColors.ink, fontSize: 16),
      bodyMedium: TextStyle(color: PesowiseColors.ink, fontSize: 14),
      bodySmall: TextStyle(color: PesowiseColors.muted, fontSize: 12),
      titleLarge: TextStyle(
        color: PesowiseColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
      titleMedium: TextStyle(
        color: PesowiseColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PesowiseColors.blushBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PesowiseColors.blushBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: PesowiseColors.blushCard,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
