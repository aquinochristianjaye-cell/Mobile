import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/worker_assignment_service.dart';
import 'common/panel.dart';

/// ===================== BAY STATUS =====================

class BayStatusPanel extends StatefulWidget {
  const BayStatusPanel({super.key});

  @override
  State<BayStatusPanel> createState() =>
      _BayStatusPanelState();
}

class _BayStatusPanelState
    extends State<BayStatusPanel> {
  List<dynamic> assignments = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    loadAssignments();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadAssignments();
      },
    );
  }

  Future<void> loadAssignments() async {
    try {
      final data =
          await WorkerAssignmentService
              .getActiveAssignments();

      if (!mounted) return;

      setState(() {
        assignments = data;
      });
    } catch (e) {
      // Keep the current panel state if the request fails.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bay1InUse = assignments.any(
      (assignment) =>
          assignment['wash_bay_id'] == 1 &&
          assignment['status'] == 'washing',
    );

    final bay2InUse = assignments.any(
      (assignment) =>
          assignment['wash_bay_id'] == 2 &&
          assignment['status'] == 'washing',
    );

    final freeCount =
        (bay1InUse ? 0 : 1) +
        (bay2InUse ? 0 : 1);

    const totalCount = 2;

    return Panel(
      eyebrow: 'Bay Status',
      title: 'Available Wash',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: freeCount > 0
                    ? AppColors.glow(AppColors.water, strength: 0.5)
                    : null,
              ),
              child: CustomPaint(
                painter: _DialPainter(
                  fraction:
                      freeCount / totalCount,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: displayStyle(
                            size: 34,
                            weight:
                                FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '$freeCount',
                            ),
                            TextSpan(
                              text:
                                  '/$totalCount',
                              style:
                                  const TextStyle(
                                color:
                                    AppColors
                                        .water,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'BAYS FREE',
                        style:
                            const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.1,
                          color:
                              AppColors
                                  .textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _BayRow(
            name: 'Wash Bay 1',
            subtitle: bay1InUse
                ? 'Currently washing'
                : 'Ready for next truck',
            available: !bay1InUse,
          ),

          const SizedBox(height: 8),

          _BayRow(
            name: 'Wash Bay 2',
            subtitle: bay2InUse
                ? 'Currently washing'
                : 'Ready for next truck',
            available: !bay2InUse,
          ),
        ],
      ),
    );
  }
}

/// ===================== BAY DIAL =====================

class _DialPainter extends CustomPainter {
  final double fraction;

  _DialPainter({
    required this.fraction,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        (size.width - 10) / 2;

    const strokeWidth = 9.0;

    // Faint inner disc so the dial reads as an "instrument" rather than
    // a flat ring floating on the panel.
    final discPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12);
    canvas.drawCircle(
      center,
      radius - strokeWidth / 2 - 4,
      discPaint,
    );

    final trackPaint = Paint()
      ..color = AppColors.panel2
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(
      center,
      radius,
      trackPaint,
    );

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    const startAngle =
        -3.14159 / 2;

    final sweepAngle =
        3.14159 * 2 * fraction;

    if (fraction > 0) {
      // Soft blurred glow pass underneath the crisp arc for extra depth.
      final glowPaint = Paint()
        ..shader = const SweepGradient(
          colors: [
            AppColors.water,
            AppColors.soap,
            AppColors.ok,
          ],
          startAngle: 0,
          endAngle: 3.14159 * 2,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 7
        ..strokeCap = StrokeCap.round
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      final gradient = const SweepGradient(
        colors: [
          AppColors.water,
          AppColors.soap,
          AppColors.ok,
        ],
        startAngle: 0,
        endAngle: 3.14159 * 2,
      );

      final fillPaint = Paint()
        ..shader =
            gradient.createShader(rect)
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap =
            StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        fillPaint,
      );

      // Bright little cap at the leading edge of the arc, like a needle tip.
      final tipAngle = startAngle + sweepAngle;
      final tipCenter = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      final tipPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(tipCenter, strokeWidth / 3.2, tipPaint);
    }
  }

  @override
  bool shouldRepaint(
    covariant _DialPainter oldDelegate,
  ) {
    return oldDelegate.fraction !=
        fraction;
  }
}

/// ===================== BAY ROW =====================

class _BayRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool available;

  const _BayRow({
    required this.name,
    required this.subtitle,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final color = available
        ? AppColors.ok
        : AppColors.crit;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.panel2,
            AppColors.panel2.withValues(alpha: 0.7),
          ],
        ),
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: available
              ? color.withValues(alpha: 0.28)
              : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(7),
              boxShadow: available
                  ? AppColors.glow(color, strength: 0.35)
                  : null,
            ),
            child: Icon(
              available
                  ? Icons.check
                  : Icons.close,
              size: 15,
              color: color,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: bodyStyle(
                    size: 12.5,
                    weight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  subtitle,
                  style: bodyStyle(
                    size: 10,
                    color:
                        AppColors
                            .textFaint,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(
                      100),
            ),
            child: Text(
              available
                  ? 'AVAILABLE'
                  : 'IN USE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

