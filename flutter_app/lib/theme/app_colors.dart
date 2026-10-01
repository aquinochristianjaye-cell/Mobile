import 'package:flutter/material.dart';

/// ===================== COLORS =====================

class AppColors {
  static const bg = Color(0xFF0C1218);
  static const panel = Color(0xFF1A242C);
  static const panel2 = Color(0xFF212D36);

  // Subtle diagonal gradient stops used inside panel/card surfaces
  // to give them a soft sheen instead of a flat fill.
  static const panelTop = Color(0xFF1E2932);
  static const panelBottom = Color(0xFF161E25);

  static final line = Colors.white.withValues(alpha: 0.07);
  static final lineStrong = Colors.white.withValues(alpha: 0.14);
  static final lineGlow = Colors.white.withValues(alpha: 0.22);

  static const text = Color(0xFFEAF2F4);
  static const textDim = Color(0xFF93A6AE);
  static const textFaint = Color(0xFF5C707A);

  static const water = Color(0xFF2FB8D9);
  static const waterDeep = Color(0xFF1C6E82);
  static const soap = Color(0xFF8C9CF5);
  static const disinfect = Color(0xFFC583F0);

  static const ok = Color(0xFF38D399);
  static const warn = Color(0xFFF5B94D);
  static const crit = Color(0xFFF0605C);

  // Shared "elevation" shadow used behind cards for real depth.
  static List<BoxShadow> elevation({double strength = 1}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28 * strength),
          blurRadius: 22 * strength,
          offset: Offset(0, 10 * strength),
          spreadRadius: -6 * strength,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18 * strength),
          blurRadius: 6 * strength,
          offset: Offset(0, 2 * strength),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35 * strength),
          blurRadius: 18 * strength,
          spreadRadius: -4 * strength,
        ),
      ];
}

