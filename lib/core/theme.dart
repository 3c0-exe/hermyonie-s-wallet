import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PesowiseColors {
  static const background  = Color(0xFFFEF5F7);
  static const blushCard   = Color(0xFFFDDDE8);
  static const blushBorder = Color(0xFFF5DDE6);
  static const chipBg      = Color(0xFFFCEAF0);
  static const accent      = Color(0xFFF4A7C0);
  static const strong      = Color(0xFFD4537E);
  static const muted       = Color(0xFFE0AAC0);
  static const white       = Color(0xFFFFFFFF);
}

class PesowiseTheme {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: PesowiseColors.background,
    colorScheme: ColorScheme.light(
      primary: PesowiseColors.strong,
      secondary: PesowiseColors.accent,
      surface: PesowiseColors.white,
    ),
    textTheme: GoogleFonts.quicksandTextTheme().apply(
      bodyColor: PesowiseColors.strong,
      displayColor: PesowiseColors.strong,
    ),
    useMaterial3: true,
  );
}