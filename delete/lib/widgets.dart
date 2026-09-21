import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'driver_session.dart';
import 'settings.dart';

// ===========================================================================
// FEEDBACK
// ===========================================================================

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final c = context.c;
  final t = context.t;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surfaceHigh,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: error ? c.danger : c.line),
      ),
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: error ? c.danger : c.success,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: t.body.copyWith(fontSize: 15)),
          ),
        ],
      ),
    ),
  );
}

// ===========================================================================
// BRAND
// ===========================================================================

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.water_drop_rounded, color: c.onAccent, size: size * 0.55),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.subtitle = 'Driver portal'});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      children: [
        const BrandMark(),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aquino Wash Station', style: t.heading),
            const SizedBox(height: 2),
            Text(subtitle, style: t.caption),
          ],
        ),
      ],
    );
  }
}

/// Faint water lines behind the top of a screen.
class WaveBackdrop extends StatelessWidget {
  const WaveBackdrop({super.key, this.height = 240});
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _WavePainter(context.c.accent)),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withAlpha(52 - i * 10);
      final baseY = size.height * (0.30 + i * 0.15);
      final path = Path()..moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 4) {
        final y = baseY +
            math.sin(x / size.width * 2 * math.pi * 1.4 + i * 1.3) * (9 + i * 2);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.color != color;
}

// ===========================================================================
// HEADERS & AVATAR
// ===========================================================================

class DriverAvatar extends StatelessWidget {
  const DriverAvatar({super.key, this.size = 46});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Semantics(
      button: true,
      label: 'Open settings',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsDriverScreen()),
          );
        },
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accentSoft,
            shape: BoxShape.circle,
            border: Border.all(color: c.accent.withAlpha(120), width: 1.5),
          ),
          child: Text(
            DriverSession.initials,
            style: t.label.copyWith(color: c.accent, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: c.line),
          ),
          child: Icon(icon, color: c.text, size: 22),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      children: [
        if (onBack != null) ...[
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: onBack,
            semanticLabel: 'Go back',
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) Text(eyebrow!, style: t.caption),
              Text(title, style: t.title),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ===========================================================================
// CONTAINERS
// ===========================================================================

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.line),
      ),
      child: child,
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: t.label.copyWith(color: color, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A truck plate, styled like a real plate so it reads at a glance.
class PlateTag extends StatelessWidget {
  const PlateTag(this.plate, {super.key, this.fontSize = 26});
  final String plate;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      label: 'Plate number $plate',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: fontSize * 0.55, vertical: fontSize * 0.2),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F7),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFF0A1721), width: 2.5),
          ),
          child: Text(
            plate.toUpperCase(),
            style: t.plate.copyWith(fontSize: fontSize),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, color: c.accent, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, style: t.heading, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: t.bodyMuted.copyWith(fontSize: 15), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ===========================================================================
// FORM
// ===========================================================================

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.error,
    this.helper,
    this.optional = false,
    this.obscure = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.capitalization = TextCapitalization.none,
    this.formatters,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.autofillHints,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final String? error;
  final String? helper;
  final bool optional;
  final bool obscure;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final hasError = error != null;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: t.label),
            if (optional) ...[
              const SizedBox(width: 6),
              Text('optional', style: t.caption.copyWith(color: c.textFaint)),
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: capitalization,
          inputFormatters: formatters,
          autofillHints: autofillHints,
          maxLength: maxLength,
          cursorColor: c.accent,
          style: t.body.copyWith(fontWeight: FontWeight.w500, fontSize: 17),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: t.body.copyWith(color: c.textFaint, fontSize: 16),
            prefixIcon: icon == null ? null : Icon(icon, color: c.textMuted, size: 22),
            suffixIcon: suffix,
            filled: true,
            fillColor: c.field,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            border: border(hasError ? c.danger : c.line, 1.5),
            enabledBorder: border(hasError ? c.danger : c.line, 1.5),
            focusedBorder: border(hasError ? c.danger : c.accent, 2),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.error_outline_rounded, size: 16, color: c.danger),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(error!, style: t.caption.copyWith(color: c.danger, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(helper!, style: t.caption),
          ),
      ],
    );
  }
}

// ===========================================================================
// BUTTONS
// ===========================================================================

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final enabled = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.accent.withAlpha(150),
          disabledForegroundColor: c.onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: c.onAccent),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: c.onAccent),
                    const SizedBox(width: 10),
                  ],
                  Text(label, style: t.button),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: BorderSide(color: c.line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: c.text),
              const SizedBox(width: 10),
            ],
            Text(label, style: t.button.copyWith(color: c.text)),
          ],
        ),
      ),
    );
  }
}

/// Sticky bar for the main action, sits where the thumb already is.
/// Use as Scaffold.bottomNavigationBar so snackbars float above it.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 32,
            padding: const EdgeInsets.all(4),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? c.accent : c.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: value ? c.accent : c.line),
            ),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? c.onAccent : c.textMuted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// BOOKING FLOW
// ===========================================================================

/// Booking is a real sequence (details, review, gate pass), so numbering it is useful.
class FlowProgress extends StatelessWidget {
  const FlowProgress({super.key, required this.step});
  final int step; // 1..3

  static const _labels = ['Details', 'Review', 'Gate pass'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Semantics(
      label: 'Step $step of 3: ${_labels[step - 1]}',
      child: ExcludeSemantics(
        child: Row(
          children: List.generate(3, (i) {
            final active = i < step;
            final current = i == step - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      decoration: BoxDecoration(
                        color: active ? c.accent : c.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _labels[i],
                      style: t.caption.copyWith(
                        color: current ? c.text : c.textFaint,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DashedLine extends StatelessWidget {
  const DashedLine({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 11).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: 6,
              height: 2,
              child: DecoratedBox(decoration: BoxDecoration(color: c.line)),
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// WASH TRACKER
// ===========================================================================

/// Four-stop progress line: on the way, arrived, washing, done.
/// [stepIndex] 0..3. The current stop pulses gently (skipped when the device
/// asks for reduced motion).
class WashTracker extends StatefulWidget {
  const WashTracker({super.key, required this.stepIndex});
  final int stepIndex;

  @override
  State<WashTracker> createState() => _WashTrackerState();
}

class _WashTrackerState extends State<WashTracker> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  static const _labels = ['On the way', 'Arrived', 'Washing', 'Done'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _node(bool done, bool current, AppColors c) {
    if (done) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: 18, color: c.onAccent),
      );
    }
    if (current) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final v = _pulse.value;
          return Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
              border: Border.all(color: c.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withAlpha((40 + 80 * v).round()),
                  blurRadius: 4 + 8 * v,
                  spreadRadius: 1 + 3 * v,
                ),
              ],
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            ),
          );
        },
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.line, width: 2.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final int step = widget.stepIndex.clamp(0, 3).toInt();
    final complete = step >= 3;

    return Semantics(
      label: 'Wash progress: ${_labels[step]}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (i) {
            final done = i < step || (complete && i == 3);
            final current = i == step && !complete;
            final leftActive = i <= step;
            final rightActive = i < step;

            return Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i == 0
                                ? Colors.transparent
                                : (leftActive ? c.accent : c.line),
                          ),
                        ),
                        _node(done, current, c),
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i == 3
                                ? Colors.transparent
                                : (rightActive ? c.accent : c.line),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: t.caption.copyWith(
                      fontSize: 12.5,
                      color: current ? c.text : (done ? c.textMuted : c.textFaint),
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
