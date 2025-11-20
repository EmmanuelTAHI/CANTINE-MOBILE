import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charte graphique HEG - Couleurs officielles
class HEGColors {
  // Violet principal HEG
  static const Color violet = Color(0xFF902C8E);
  static const Color violetDark = Color(0xFF7A2577);
  
  // Gris HEG
  static const Color gris = Color(0xFF58595B);
  static const Color grisClair = Color(0xFFF4F4F5);
  
  // Couleurs supplémentaires
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

/// Thème de l'application Flutter HEG
class HEGTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: HEGColors.violet,
        primaryContainer: HEGColors.violetDark,
        secondary: HEGColors.gris,
        surface: HEGColors.white,
        surfaceContainerHighest: HEGColors.grisClair,
        error: HEGColors.error,
        onPrimary: HEGColors.white,
        onSecondary: HEGColors.white,
        onSurface: HEGColors.gris,
        onError: HEGColors.white,
      ),
      scaffoldBackgroundColor: HEGColors.grisClair,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: HEGColors.violet,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: HEGColors.violet,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: HEGColors.violet,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: HEGColors.violet,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: HEGColors.gris,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: HEGColors.gris,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: HEGColors.gris,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: HEGColors.gris.withValues(alpha: 0.7),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HEGColors.white,
        foregroundColor: HEGColors.violet,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: HEGColors.violet,
        ),
      ),
      cardTheme: CardThemeData(
        color: HEGColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HEGColors.violet,
          foregroundColor: HEGColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HEGColors.violet,
          side: const BorderSide(color: HEGColors.violet, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HEGColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HEGColors.gris.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HEGColors.gris.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HEGColors.violet, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HEGColors.error),
        ),
        labelStyle: GoogleFonts.inter(
          color: HEGColors.gris,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: HEGColors.gris.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
    );
  }
}


