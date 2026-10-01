import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ===================== TEXT STYLES =====================

TextStyle displayStyle({
  double size = 16,
  FontWeight weight = FontWeight.w600,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: weight,
    fontSize: size,
    letterSpacing: 0.2,
    color: color ?? AppColors.text,
  );
}

TextStyle bodyStyle({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return TextStyle(
    fontWeight: weight,
    fontSize: size,
    color: color ?? AppColors.text,
  );
}

TextStyle monoStyle({
  double size = 13,
  FontWeight weight = FontWeight.w500,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontWeight: weight,
    fontSize: size,
    color: color ?? AppColors.text,
  );
}

TextStyle eyebrowStyle() {
  return const TextStyle(
    fontSize: 10,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textFaint,
  );
}

