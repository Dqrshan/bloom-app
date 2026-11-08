import 'package:flutter/material.dart';

/// Bloom's brand ramps. The rose ramp is the identity; the accents are
/// reserved for state, never decoration.
class BloomColors {
  static const rose50 = Color(0xFFF7E4EA);
  static const rose100 = Color(0xFFEFD4DB);
  static const rose200 = Color(0xFFE8C3CF);
  static const rose300 = Color(0xFFD99AAE);
  static const rose400 = Color(0xFFC4748B);
  static const rose500 = Color(0xFFD65A78);
  static const rose600 = Color(0xFFB83E5C);
  static const rose700 = Color(0xFF9A2E4C);

  static const ink = Color(0xFF1B1B2E);
  static const inkLight = Color(0xFF4A4A66);
  static const muted = Color(0xFF7C7C96);
  static const surface = Color(0xFFFAFAFD);
  static const surfaceAlt = Color(0xFFF4F4F9);
  static const divider = Color(0xFFE9E9F0);

  static const lavender = Color(0xFF9B8EC4);
  static const sage = Color(0xFF6BB88C);
  static const peach = Color(0xFFE89B7B);
  static const sky = Color(0xFF7BB8D9);

  static const periodRed = Color(0xFFD65A78);
  static const fertileGreen = Color(0xFF6BB88C);
  static const predictedOrange = Color(0xFFE89B7B);
}

/// Semantic roles resolved for the active brightness.
///
/// Every screen reads state colors from here rather than from raw hex, so
/// period, fertile and predicted stay legible in both schemes.
class BloomPalette {
  const BloomPalette({
    required this.ink,
    required this.inkLight,
    required this.muted,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceHigh,
    required this.divider,
    required this.outline,
    required this.period,
    required this.periodContainer,
    required this.fertile,
    required this.fertileContainer,
    required this.predicted,
    required this.predictedContainer,
    required this.notes,
    required this.notesContainer,
    required this.onAccent,
    required this.glow,
  });

  final Color ink;
  final Color inkLight;
  final Color muted;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceHigh;
  final Color divider;
  final Color outline;

  final Color period;
  final Color periodContainer;
  final Color fertile;
  final Color fertileContainer;
  final Color predicted;
  final Color predictedContainer;
  final Color notes;
  final Color notesContainer;

  /// Foreground that sits on a saturated fill (period, fertile, predicted).
  final Color onAccent;

  /// The single soft light Bloom's dial is allowed to cast.
  final Color glow;

  static const light = BloomPalette(
    ink: BloomColors.ink,
    inkLight: BloomColors.inkLight,
    muted: BloomColors.muted,
    surface: Colors.white,
    surfaceAlt: BloomColors.surface,
    surfaceHigh: BloomColors.surfaceAlt,
    divider: BloomColors.divider,
    outline: Color(0xFFC9C8D6),
    period: BloomColors.periodRed,
    periodContainer: Color(0xFFFBE7EC),
    fertile: BloomColors.fertileGreen,
    fertileContainer: Color(0xFFE4F3EA),
    predicted: Color(0xFFCE7346),
    predictedContainer: Color(0xFFFBEBE1),
    notes: BloomColors.lavender,
    notesContainer: Color(0xFFEDE9F7),
    onAccent: Colors.white,
    glow: Color(0x33D65A78),
  );

  static const dark = BloomPalette(
    ink: Color(0xFFF1F0F6),
    inkLight: Color(0xFFC9C8D8),
    muted: Color(0xFF9493A8),
    surface: Color(0xFF1A1A23),
    surfaceAlt: Color(0xFF14141B),
    surfaceHigh: Color(0xFF23232E),
    divider: Color(0xFF2E2E3A),
    outline: Color(0xFF6B6A7D),
    period: Color(0xFFE88BA2),
    periodContainer: Color(0xFF3A1A25),
    fertile: Color(0xFF8FD3AA),
    fertileContainer: Color(0xFF17301F),
    predicted: Color(0xFFF0AE86),
    predictedContainer: Color(0xFF352116),
    notes: Color(0xFFBCB0E4),
    notesContainer: Color(0xFF272238),
    onAccent: Color(0xFF22101A),
    glow: Color(0x3DD65A78),
  );

  static BloomPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
