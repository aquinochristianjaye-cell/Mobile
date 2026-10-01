import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import 'pulsing_dot.dart';

/// ===================== STATUS PILL =====================

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, 
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        5,
        11,
        5,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.lineStrong,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          PulsingDot(color: color, size: 6),

          const SizedBox(width: 8),

          Text(
            label,
            style: bodyStyle(
              size: 11.5,
              weight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

