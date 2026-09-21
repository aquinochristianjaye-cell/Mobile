import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Barlow is bundled in assets/fonts (see pubspec_snippet.yaml). It was drawn
/// from highway signs and license plates, which suits a truck app. If the font
/// isn't registered, Flutter quietly falls back to the platform font.
const String kFontFamily = 'Barlow';

// ---------------------------------------------------------------------------
// COLOR TOKENS
// ---------------------------------------------------------------------------
//
// Night shift  = dark theme  (evening / early-morning hauls, low glare)
// Daylight     = light theme (bright sun on a phone screen)
//
// "accent" is the water color from your original brand (#22B8CF) on dark, and a
// deeper teal on light so text and buttons keep enough contrast in sunlight.
// "signal" is hi-vis amber: used only for "on the way" / attention states.

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.field,
    required this.line,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.signal,
    required this.signalSoft,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color field;
  final Color line;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color signal;
  final Color signalSoft;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;

  static const AppColors dark = AppColors(
    bg: Color(0xFF0A1721),
    surface: Color(0xFF12242F),
    surfaceHigh: Color(0xFF1A3240),
    field: Color(0xFF0E1D27),
    line: Color(0xFF27404F),
    text: Color(0xFFEAF3F6),
    textMuted: Color(0xFF9AB2BD),
    textFaint: Color(0xFF6F8996),
    accent: Color(0xFF22B8CF),
    onAccent: Color(0xFF04202A),
    accentSoft: Color(0xFF123844),
    signal: Color(0xFFFFB020),
    signalSoft: Color(0xFF3A2C10),
    success: Color(0xFF3DD68C),
    successSoft: Color(0xFF123A2A),
    danger: Color(0xFFFF6B5E),
    dangerSoft: Color(0xFF3D1B1A),
  );

  static const AppColors light = AppColors(
    bg: Color(0xFFEDF3F5),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE3ECEF),
    field: Color(0xFFF2F7F9),
    line: Color(0xFFCFDDE3),
    text: Color(0xFF0C1822),
    textMuted: Color(0xFF526872),
    textFaint: Color(0xFF7C919B),
    accent: Color(0xFF0A7F94),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD9F1F5),
    signal: Color(0xFFB45309),
    signalSoft: Color(0xFFFDECD2),
    success: Color(0xFF15803D),
    successSoft: Color(0xFFDCF3E3),
    danger: Color(0xFFB42318),
    dangerSoft: Color(0xFFFDE4E1),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHigh,
    Color? field,
    Color? line,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? signal,
    Color? signalSoft,
    Color? success,
    Color? successSoft,
    Color? danger,
    Color? dangerSoft,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      field: field ?? this.field,
      line: line ?? this.line,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      signal: signal ?? this.signal,
      signalSoft: signalSoft ?? this.signalSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      field: l(field, other.field),
      line: l(line, other.line),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      signal: l(signal, other.signal),
      signalSoft: l(signalSoft, other.signalSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
    );
  }
}

// ---------------------------------------------------------------------------
// TYPE SCALE
// ---------------------------------------------------------------------------
//
// Sizes are deliberately a step larger than typical apps: drivers read this
// at arm's length, outdoors, often one-handed. Labels are sentence case.

class AppType {
  const AppType(this.c);
  final AppColors c;

  TextStyle _s(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? spacing,
  }) {
    return TextStyle(
      fontFamily: kFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );
  }

  TextStyle get display => _s(30, FontWeight.w700, c.text, height: 1.1, spacing: -0.3);
  TextStyle get title => _s(22, FontWeight.w700, c.text, height: 1.2);
  TextStyle get heading => _s(18, FontWeight.w700, c.text, height: 1.25);
  TextStyle get body => _s(16, FontWeight.w400, c.text, height: 1.4);
  TextStyle get bodyMuted => _s(16, FontWeight.w400, c.textMuted, height: 1.4);
  TextStyle get label => _s(14, FontWeight.w600, c.textMuted, height: 1.2);
  TextStyle get caption => _s(13, FontWeight.w500, c.textMuted, height: 1.35);
  TextStyle get button => _s(17, FontWeight.w700, c.onAccent, spacing: 0.2);

  /// Plate numbers and other figures that should line up.
  TextStyle get plate => const TextStyle(
        fontFamily: kFontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
        height: 1.1,
        color: Color(0xFF0A1721),
        fontFeatures: [FontFeature.tabularFigures()],
      );
}

extension AppThemeContext on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
  AppType get t => AppType(c);
}

// ---------------------------------------------------------------------------
// THEME DATA
// ---------------------------------------------------------------------------

class AppTheme {
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);
  static ThemeData get light => _build(Brightness.light, AppColors.light);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: kFontFamily,
      scaffoldBackgroundColor: c.bg,
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionHandleColor: c.accent,
        selectionColor: c.accent.withAlpha(70),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceHigh,
      ),
      extensions: <ThemeExtension<dynamic>>[c],
    );
  }
}

// ---------------------------------------------------------------------------
// THEME SWITCH
// ---------------------------------------------------------------------------

/// Controls Night shift (dark) / Daylight (light).
/// Starts in dark to match the original look. The choice is kept in memory
/// only; add shared_preferences later if you want it remembered.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.dark);

  void setDark(bool dark) {
    value = dark ? ThemeMode.dark : ThemeMode.light;
  }
}

final ThemeController themeController = ThemeController();
