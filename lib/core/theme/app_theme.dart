import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hosh/core/theme/app_tokens.dart';

ThemeData buildHooshTheme() {
  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: HooshColors.primary,
        brightness: Brightness.light,
        primary: HooshColors.primary,
        secondary: HooshColors.secondary,
        tertiary: HooshColors.tertiary,
        surface: HooshColors.surface,
      ).copyWith(
        primaryContainer: HooshColors.primaryContainer,
        secondaryContainer: HooshColors.sky,
        tertiaryContainer: const Color(0xFFFFF4CC),
        surfaceContainerLowest: HooshColors.surfaceLowest,
        surfaceContainerLow: HooshColors.surfaceLow,
        surfaceContainerHigh: HooshColors.surfaceHigh,
        onSurface: HooshColors.onSurface,
      );

  final TextTheme base = ThemeData.light().textTheme;
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: HooshColors.surface,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.publicSans(
        fontSize: 56,
        fontWeight: FontWeight.w900,
        color: HooshColors.onSurface,
        height: 1,
      ),
      headlineLarge: GoogleFonts.publicSans(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: HooshColors.onSurface,
        height: 1.1,
      ),
      headlineMedium: GoogleFonts.publicSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: HooshColors.onSurface,
        height: 1.2,
      ),
      titleMedium: GoogleFonts.publicSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: HooshColors.onSurface,
        height: 1.2,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: HooshColors.onSurface,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: HooshColors.onSurfaceSoft,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: HooshColors.secondary,
        height: 1.33,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: HooshColors.secondary,
        letterSpacing: 1,
        height: 1.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HooshColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: HooshRadii.md,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: HooshRadii.md,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: HooshRadii.md,
        borderSide: BorderSide(
          color: HooshColors.secondary.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 8,
      activeTrackColor: HooshColors.primary,
      inactiveTrackColor: HooshColors.surfaceHigh,
      thumbColor: HooshColors.primary,
      overlayColor: Color(0x33AC2D00),
    ),
    iconTheme: const IconThemeData(color: HooshColors.onSurface),
  );
}
