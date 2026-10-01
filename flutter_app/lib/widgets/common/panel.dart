import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import 'rise_in.dart';

/// ===================== PANEL =====================

class Panel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;
  final Widget? trailing;

  const Panel({super.key, 
    required this.eyebrow,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return RiseIn(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.elevation(),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.panelTop,
                AppColors.panelBottom,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // Thin glowing accent bar — a small signature touch that
              // hints at the panel's "liveness" without shouting.
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.water.withValues(alpha: 0.85),
                        AppColors.soap.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: eyebrowStyle(),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        title,
                        style: displayStyle(
                          size: 15,
                        ),
                      ),
                    ],
                  ),

                  ?trailing,
                ],
              ),

              const SizedBox(height: 12),

              child,
            ],
          ),
        ),
      ),
    );
  }
}

