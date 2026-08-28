import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BloomColors {
  static const rose50 = Color(0xFFFFF0F3);
  static const rose100 = Color(0xFFFFD9E2);
  static const rose200 = Color(0xFFFFB3C5);
  static const rose300 = Color(0xFFFF8DA8);
  static const rose400 = Color(0xFFFF6B8A);
  static const rose500 = Color(0xFFE85577);
  static const rose600 = Color(0xFFD63D5F);
  static const rose700 = Color(0xFFB82E4D);

  static const ink = Color(0xFF1A1A2E);
  static const inkLight = Color(0xFF3D3D56);
  static const muted = Color(0xFF8E8EA0);
  static const surface = Color(0xFFF8F8FC);
  static const surfaceAlt = Color(0xFFF0F0F6);
  static const divider = Color(0xFFE8E8EE);

  static const lavender = Color(0xFF9B8EC4);
  static const sage = Color(0xFF6BB88C);
  static const peach = Color(0xFFE89B7B);
  static const sky = Color(0xFF7BB8D9);

  static const periodRed = Color(0xFFE85577);
  static const periodRedLight = Color(0x1AE85577);
  static const fertileGreen = Color(0xFF6BB88C);
  static const fertileGreenLight = Color(0x1A6BB88C);
  static const predictedOrange = Color(0xFFE89B7B);
  static const predictedOrangeLight = Color(0x1AE89B7B);
}

ThemeData bloomTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: BloomColors.rose500,
    primary: BloomColors.rose500,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: BloomColors.ink,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: BloomColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: BloomColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: const TextStyle(
        color: BloomColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BloomColors.divider, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 72,
      indicatorColor: BloomColors.rose100,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BloomColors.rose500,
            letterSpacing: 0.2,
          );
        }
        return const TextStyle(fontSize: 11, color: BloomColors.muted, letterSpacing: 0.2);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BloomColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BloomColors.rose500, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: BloomColors.muted, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BloomColors.rose500,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: BloomColors.divider),
        foregroundColor: BloomColors.ink,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: BloomColors.divider,
      thickness: 0.5,
      space: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w700, letterSpacing: -1.5),
      displayMedium: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w700, letterSpacing: -1),
      displaySmall: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      headlineLarge: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      headlineSmall: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleLarge: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.1),
      titleSmall: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: BloomColors.ink, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: BloomColors.inkLight, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: BloomColors.muted, fontSize: 12, height: 1.3),
      labelLarge: TextStyle(color: BloomColors.ink, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: TextStyle(color: BloomColors.inkLight, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: TextStyle(color: BloomColors.muted, fontWeight: FontWeight.w500, fontSize: 11),
    ),
  );
}
