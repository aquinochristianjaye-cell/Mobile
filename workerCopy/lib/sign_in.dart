import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'widgets.dart'; // showAppSnack
import 'worker_dashboard.dart';
import 'worker_session.dart';

// ---- Palette (local, so this file doesn't depend on app_theme.dart) ----
const _bg = Color(0xFF08141C);
const _card = Color(0xFF11232F);
const _field = Color(0xFF0E1D28);
const _border = Color(0xFF1F3B49);
const _cyan = Color(0xFF22B8D1);
const _text = Color(0xFFE8F4F8);
const _muted = Color(0xFF8CA3AE);

/// Content-only widget (no Scaffold). Drop it inside your screen, with or
/// without a scroll view around it.
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _workerIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _workerIdError;
  String? _passwordError;

  @override
  void dispose() {
    _workerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final idErr = _workerIdController.text.trim().isEmpty
        ? 'Enter your Worker ID.'
        : null;
    final pwErr =
        _passwordController.text.isEmpty ? 'Enter your password.' : null;

    setState(() {
      _workerIdError = idErr;
      _passwordError = pwErr;
    });

    return idErr == null && pwErr == null;
  }

  // ---- API logic: unchanged ----
  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/worker/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'worker_id': _workerIdController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (!mounted) return;

      if (response.statusCode == 200 && data is Map) {
        final worker = data['worker'];

        final String fullName =
            '${worker['first_name']} ${worker['last_name']}';
        final String code = worker['worker_id'].toString();

        await WorkerSession.start(
          workerId: worker['id'] is int ? worker['id'] : null,
          workerName: fullName,
          code: code,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerDashboardScreen(
              workerId: worker['id'],
              workerName: fullName,
              workerIdNumber: code,
            ),
          ),
        );
      } else if (data is Map && data['message'] != null) {
        showAppSnack(context, data['message'].toString(), error: true);
      } else if (data == null || response.statusCode == 200) {
        showAppSnack(
          context,
          'The server sent an unexpected response. Try again in a moment.',
          error: true,
        );
      } else {
        showAppSnack(context, 'Worker ID or password is incorrect.',
            error: true);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Can\'t reach the server. Check your connection and make sure Laravel is running.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    // Works both as a full screen and inside a parent that scrolls:
    // when height is unbounded (inside a scroll view) use the screen height.
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.vertical;

        return SizedBox(
          height: h,
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _BackdropPainter()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 56),
                child: Column(
                  children: [
                    _buildHeader(),
                    const Spacer(),
                    _buildCard(),
                    const SizedBox(height: 18),
                    const Text(
                      'No account yet? Ask the station admin to create one for you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: const Color(0xFF12303B),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: _cyan.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.22),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.water_drop_rounded, size: 64, color: _cyan),
        ),
        const SizedBox(height: 22),
        const Text(
          'AQUINO WASH STATION',
          style: TextStyle(
            color: _cyan,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome back',
          style: TextStyle(
            color: _text,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Worker Login',
          style: TextStyle(color: _muted, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.08),
            blurRadius: 30,
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Worker ID'),
            _input(
              controller: _workerIdController,
              hint: 'Enter your Worker ID',
              icon: Icons.badge_outlined,
              error: _workerIdError,
              action: TextInputAction.next,
              hints: const [AutofillHints.username],
              onChanged: (_) {
                if (_workerIdError != null) {
                  setState(() => _workerIdError = null);
                }
              },
            ),
            const SizedBox(height: 22),
            _label('Password'),
            _input(
              controller: _passwordController,
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              error: _passwordError,
              obscure: _obscurePassword,
              action: TextInputAction.done,
              hints: const [AutofillHints.password],
              onSubmitted: (_) => _handleLogin(),
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
              suffix: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _muted,
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  disabledBackgroundColor: _cyan.withValues(alpha: 0.6),
                  foregroundColor: const Color(0xFF06141B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF06141B),
                        ),
                      )
                    : const Text('Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          s,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? error,
    bool obscure = false,
    TextInputAction? action,
    Iterable<String>? hints,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c),
        );

    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      autofillHints: hints,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: _cyan,
      style: const TextStyle(color: _text, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _muted.withValues(alpha: 0.7)),
        errorText: error,
        filled: true,
        fillColor: _field,
        prefixIcon: Icon(icon, color: _muted, size: 24),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
        enabledBorder: border(_border),
        focusedBorder: border(_cyan),
        errorBorder: border(const Color(0xFFE5645F)),
        focusedErrorBorder: border(const Color(0xFFE5645F)),
      ),
    );
  }
}

/// Soft glowing circles and faint wave lines behind the screen.
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top glow
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.75),
          radius: 0.9,
          colors: [_cyan.withValues(alpha: 0.12), Colors.transparent],
        ).createShader(Offset.zero & size),
    );

    final fill = Paint()..color = _cyan.withValues(alpha: 0.07);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _cyan.withValues(alpha: 0.22);

    void circle(Offset c, double r) {
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, stroke);
    }

    circle(Offset(w * 0.05, h * 0.0), w * 0.28); // top-left
    circle(Offset(w * 1.02, h * 0.23), w * 0.17); // right
    circle(Offset(w * 0.0, h * 1.0), w * 0.2); // bottom-left
    circle(Offset(w * 0.95, h * 0.98), w * 0.28); // bottom-right

    // Wave lines
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _cyan.withValues(alpha: 0.08);
    for (var i = 0; i < 4; i++) {
      final y = h * (0.07 + i * 0.045);
      final p = Path()
        ..moveTo(0, y)
        ..cubicTo(w * 0.3, y - 22, w * 0.6, y + 26, w, y - 6);
      canvas.drawPath(p, wave);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}