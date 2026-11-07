import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system.dart';
import 'colors.dart';
export 'colors.dart';

ThemeData bloomTheme() {
  final base = GoogleFonts.outfitTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: BloomColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BloomColors.rose500,
      primary: BloomColors.rose500,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: BloomColors.ink,
      surfaceTint: Colors.transparent,
    ),
    textTheme: base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w800, color: BloomColors.ink, letterSpacing: -0.8),
      displayMedium: base.displayMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: BloomColors.ink, letterSpacing: -0.4),
      displaySmall: base.displaySmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: BloomColors.ink, letterSpacing: -0.2),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: BloomColors.ink),
      titleLarge: base.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: BloomColors.ink),
      titleMedium: base.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: BloomColors.ink),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w400, color: BloomColors.inkLight, height: 1.55),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: BloomColors.inkLight, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: BloomColors.muted, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: BloomColors.inkLight, letterSpacing: 0.6),
      labelMedium: base.labelMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: BloomColors.muted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        side: const BorderSide(color: BloomColors.divider, width: 0.5),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 76,
      indicatorColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BloomColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        borderSide: const BorderSide(color: BloomColors.rose500, width: 1.5),
      ),
      hintStyle: const TextStyle(color: BloomColors.muted, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BloomColors.rose500,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BloomDesign.radiusPill)),
        textStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.2),
      ),
    ),
    dividerTheme: const DividerThemeData(color: BloomColors.divider, thickness: 1, space: 1),
    splashFactory: InkRipple.splashFactory,
  );
}
