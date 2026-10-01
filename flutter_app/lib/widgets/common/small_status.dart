import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// ===================== SMALL STATUS =====================

class SmallStatus extends StatelessWidget {
  final String text;
  final Color color;

  const SmallStatus({super.key, 
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

