import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_system.dart';
import 'colors.dart';

export 'colors.dart';

/// Outfit ships as a variable font, so weight is driven by the `wght` axis.
/// Setting `fontWeight` alone leaves the axis at its default instance, which
/// is why every style here carries both.
TextStyle _outfit(
  double size,
  double weight, {
  double? height,
  double? letterSpacing,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'Outfit',
    fontSize: size,
    fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', weight)],
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

TextTheme _textTheme(BloomPalette p) {
  return TextTheme(
    displayLarge: _outfit(
      32,
      800,
      height: 1.12,
      letterSpacing: -0.8,
      color: p.ink,
    ),
    displayMedium: _outfit(
      28,
      700,
      height: 1.15,
      letterSpacing: -0.6,
      color: p.ink,
    ),
    displaySmall: _outfit(
      24,
      700,
      height: 1.2,
      letterSpacing: -0.4,
      color: p.ink,
    ),
    headlineLarge: _outfit(
      22,
      700,
      height: 1.25,
      letterSpacing: -0.3,
      color: p.ink,
    ),
    headlineMedium: _outfit(
      20,
      700,
      height: 1.3,
      letterSpacing: -0.2,
      color: p.ink,
    ),
    headlineSmall: _outfit(
      18,
      700,
      height: 1.3,
      letterSpacing: -0.2,
      color: p.ink,
    ),
    titleLarge: _outfit(
      17,
      600,
      height: 1.35,
      letterSpacing: -0.1,
      color: p.ink,
    ),
    titleMedium: _outfit(15, 600, height: 1.4, color: p.ink),
    titleSmall: _outfit(13, 600, height: 1.4, color: p.ink),
    bodyLarge: _outfit(16, 400, height: 1.5, color: p.inkLight),
    bodyMedium: _outfit(14, 400, height: 1.5, color: p.inkLight),
    bodySmall: _outfit(12, 500, height: 1.4, color: p.muted),
    labelLarge: _outfit(14, 600, height: 1.2, color: p.ink),
    labelMedium: _outfit(12, 600, height: 1.2, color: p.inkLight),
    labelSmall: _outfit(
      11,
      600,
      height: 1.2,
      letterSpacing: 0.4,
      color: p.muted,
    ),
  );
}

ThemeData _base(BloomPalette p, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final text = _textTheme(p);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: BloomColors.rose500,
        brightness: brightness,
      ).copyWith(
        primary: isDark ? BloomColors.rose300 : BloomColors.rose500,
        onPrimary: isDark ? const Color(0xFF33101C) : Colors.white,
        primaryContainer: isDark ? BloomColors.rose700 : BloomColors.rose50,
        onPrimaryContainer: isDark ? BloomColors.rose50 : BloomColors.rose700,
        secondary: isDark ? BloomColors.rose200 : BloomColors.rose600,
        onSecondary: isDark ? const Color(0xFF33101C) : Colors.white,
        secondaryContainer: isDark
            ? const Color(0xFF452030)
            : BloomColors.rose100,
        onSecondaryContainer: isDark ? BloomColors.rose50 : BloomColors.rose700,
        tertiary: p.notes,
        onTertiary: isDark ? const Color(0xFF231B38) : Colors.white,
        tertiaryContainer: p.notesContainer,
        onTertiaryContainer: isDark
            ? BloomColors.rose50
            : const Color(0xFF3E3663),
        error: isDark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
        onError: isDark ? const Color(0xFF601410) : Colors.white,
        errorContainer: isDark
            ? const Color(0xFF8C1D18)
            : const Color(0xFFF9DEDC),
        onErrorContainer: isDark
            ? const Color(0xFFF9DEDC)
            : const Color(0xFF410E0B),
        surface: p.surface,
        onSurface: p.ink,
        onSurfaceVariant: p.inkLight,
        surfaceContainerLowest: isDark ? const Color(0xFF0C0C12) : Colors.white,
        surfaceContainerLow: isDark
            ? const Color(0xFF17171F)
            : BloomColors.surface,
        surfaceContainer: isDark
            ? const Color(0xFF1E1E28)
            : BloomColors.surfaceAlt,
        surfaceContainerHigh: isDark
            ? const Color(0xFF262631)
            : const Color(0xFFEFEFF5),
        surfaceContainerHighest: isDark
            ? const Color(0xFF30303C)
            : BloomColors.divider,
        outline: p.outline,
        outlineVariant: p.divider,
        shadow: const Color(0xFF000000),
        scrim: const Color(0xFF000000),
        inverseSurface: isDark
            ? const Color(0xFFE7E6EE)
            : const Color(0xFF303040),
        onInverseSurface: isDark
            ? const Color(0xFF303040)
            : const Color(0xFFF3F0F7),
        inversePrimary: isDark ? BloomColors.rose500 : BloomColors.rose200,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101017)
        : BloomColors.surface,
    textTheme: text,
    primaryTextTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      iconTheme: IconThemeData(color: p.ink),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? const Color(0xFF101017)
            : Colors.white,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        side: BorderSide(color: p.divider, width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: isDark
          ? BloomColors.rose700.withValues(alpha: 0.55)
          : BloomColors.rose100,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? scheme.primary : p.muted,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return _outfit(
          12,
          selected ? 600 : 500,
          letterSpacing: 0.1,
          color: selected ? p.ink : p.muted,
        );
      }),
    ),
    dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      hintStyle: _outfit(15, 400, color: p.muted),
      labelStyle: _outfit(14, 500, color: p.inkLight),
      floatingLabelStyle: _outfit(13, 600, color: scheme.primary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: isDark
            ? const Color(0xFF3A2A31)
            : BloomColors.rose200,
        disabledForegroundColor: isDark
            ? const Color(0xFF6B5A61)
            : Colors.white70,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: _outfit(15, 600, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: p.outline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: _outfit(15, 600, letterSpacing: 0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _outfit(14, 600, letterSpacing: 0.1),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceAlt,
      selectedColor: isDark
          ? BloomColors.rose700.withValues(alpha: 0.55)
          : BloomColors.rose100,
      side: BorderSide(color: p.divider, width: 1),
      labelStyle: _outfit(13, 600, color: p.inkLight),
      secondaryLabelStyle: _outfit(
        13,
        600,
        color: isDark ? BloomColors.rose50 : BloomColors.rose700,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF32323F) : BloomColors.ink,
      contentTextStyle: _outfit(14, 500, color: Colors.white),
      actionTextColor: isDark ? BloomColors.rose300 : BloomColors.rose200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      elevation: 3,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: isDark
          ? const Color(0xCC000000)
          : const Color(0x66000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.inkLight,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: _outfit(13, 400, height: 1.35, color: p.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 12,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: p.surfaceHigh,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
      trackHeight: 6,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? Colors.white
            : (isDark ? const Color(0xFF8E8DA3) : const Color(0xFFB9B8C7));
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : p.surfaceHigh;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: p.surfaceHigh,
      circularTrackColor: p.surfaceHigh,
    ),
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData bloomTheme() => _base(BloomPalette.light, Brightness.light);

ThemeData bloomDarkTheme() => _base(BloomPalette.dark, Brightness.dark);
