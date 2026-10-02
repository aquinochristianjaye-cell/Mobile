import 'package:flutter/material.dart';

/// ===================== MICRO-ANIMATION HELPERS =====================

/// A small glowing dot that gently pulses forever — used for "live" status
/// indicators (system online, bay availability, etc).
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, 
    required this.color,
    this.size = 6,
  });

  @override
  State<PulsingDot> createState() => PulsingDotState();
}

class PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer breathing halo.
            Container(
              width: widget.size + (widget.size * 2.2 * t),
              height: widget.size + (widget.size * 2.2 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: (0.35 * (1 - t)).clamp(0.0, 0.35),
                ),
              ),
            ),
            // Solid core.
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Wraps [child] with a gentle fade + rise-in animation that plays once
/// when it first enters the tree. Reused by every panel so the dashboard
/// feels like it's settling into place rather than popping in flatly.
