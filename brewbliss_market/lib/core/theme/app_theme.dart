import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(Color primaryColor) {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: DesignTokens.onPrimary,
        secondary: DesignTokens.accent,
        surface: DesignTokens.surface,
        onSurface: DesignTokens.ink,
        background: DesignTokens.background,
      ),
      scaffoldBackgroundColor: DesignTokens.background,
      canvasColor: DesignTokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.ink),
        titleTextStyle: GoogleFonts.urbanist(
          color: DesignTokens.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: _buildTextTheme(base.textTheme, false),
      cardTheme: CardTheme(
        color: DesignTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: const BorderSide(
            color: DesignTokens.muted,
            width: DesignTokens.strokeThin,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: DesignTokens.surface,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.inter(color: DesignTokens.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          side: const BorderSide(color: DesignTokens.muted, width: DesignTokens.strokeThin),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: DesignTokens.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
        ),
      ),
    );
  }

  static ThemeData dark(Color primaryColor) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        onPrimary: DesignTokens.onPrimary,
        secondary: DesignTokens.accent,
        surface: DesignTokens.darkSurface,
        onSurface: DesignTokens.darkInk,
        background: DesignTokens.darkBackground,
      ),
      scaffoldBackgroundColor: DesignTokens.darkBackground,
      canvasColor: DesignTokens.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.darkInk),
        titleTextStyle: GoogleFonts.urbanist(
          color: DesignTokens.darkInk,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: _buildTextTheme(base.textTheme, true),
      cardTheme: CardTheme(
        color: DesignTokens.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(
            color: DesignTokens.darkInk.withOpacity(0.08),
            width: DesignTokens.strokeThin,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: DesignTokens.darkSurface,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.inter(color: DesignTokens.darkInk),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          side: BorderSide(color: DesignTokens.darkInk.withOpacity(0.2), width: DesignTokens.strokeThin),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: DesignTokens.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, bool dark) {
    final color = dark ? DesignTokens.darkInk : DesignTokens.ink;
    return TextTheme(
      displayLarge: GoogleFonts.caveat(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: GoogleFonts.urbanist(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: GoogleFonts.urbanist(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.urbanist(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color.withOpacity(0.8),
      ),
    );
  }
}
