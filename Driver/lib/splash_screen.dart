import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'login_driver.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginDriverScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final fill = Curves.easeOutCubic.transform(_controller.value);
            final double rawOpacity =
                ((_controller.value - 0.55) / 0.45).clamp(0.0, 1.0).toDouble();
            final double textOpacity = Curves.easeIn.transform(rawOpacity);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 120,
                  child: CustomPaint(
                    painter: _DropFillPainter(
                      fill: fill,
                      phase: _controller.value * math.pi * 6,
                      water: c.accent,
                      outline: c.accent,
                      empty: c.accentSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: textOpacity,
                  child: Column(
                    children: [
                      Text('Aquino Wash Station', style: t.title),
                      const SizedBox(height: 8),
                      Text('Pure water. Perfect clean.', style: t.caption),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A water drop that fills from the bottom with a gently moving surface.
class _DropFillPainter extends CustomPainter {
  _DropFillPainter({
    required this.fill,
    required this.phase,
    required this.water,
    required this.outline,
    required this.empty,
  });

  final double fill; // 0..1
  final double phase;
  final Color water;
  final Color outline;
  final Color empty;

  Path _dropPath(Size s) {
    final w = s.width;
    final h = s.height;
    final p = Path()..moveTo(w / 2, 0);
    p.cubicTo(w * 0.5, h * 0.16, w * 0.95, h * 0.44, w * 0.95, h * 0.68);
    p.arcToPoint(
      Offset(w * 0.05, h * 0.68),
      radius: Radius.circular(w * 0.45),
      clockwise: true,
    );
    p.cubicTo(w * 0.05, h * 0.44, w * 0.5, h * 0.16, w / 2, 0);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final drop = _dropPath(size);

    // Empty drop
    canvas.drawPath(drop, Paint()..color = empty);

    // Water level: from the bottom up to just below the tip.
    final level = size.height * (1 - fill * 0.96);
    final amp = 6 * (1 - fill * 0.75);

    final wave = Path()..moveTo(0, size.height);
    wave.lineTo(0, level);
    for (double x = 0; x <= size.width; x += 2) {
      wave.lineTo(x, level + math.sin(x / size.width * 2 * math.pi + phase) * amp);
    }
    wave.lineTo(size.width, size.height);
    wave.close();

    canvas.save();
    canvas.clipPath(drop);
    canvas.drawPath(wave, Paint()..color = water);
    canvas.restore();

    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(covariant _DropFillPainter old) =>
      old.fill != fill || old.phase != phase || old.water != water;
}
