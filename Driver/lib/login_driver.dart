import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_theme.dart';
import 'dashboard_driver.dart';
import 'driver_session.dart';
import 'widgets.dart';

// TODO: put your project name here
const String _appName = 'AQUINO WASH STATION';

class LoginDriverScreen extends StatefulWidget {
  const LoginDriverScreen({super.key});

  @override
  State<LoginDriverScreen> createState() => _LoginDriverScreenState();
}

class _LoginDriverScreenState extends State<LoginDriverScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email and password to sign in.', error: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/driver/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
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
        // Get the logged-in driver's ID from Laravel.
        final driverId = data['driver']['id'];

        // Remember the name so the app can greet the driver.
        await DriverSession.start(
          driverId: driverId is int ? driverId : null,
          driverName: data['driver']['name']?.toString(),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreenDriver(
              driverId: driverId,
            ),
          ),
        );
      } else if (data is Map && data['message'] != null) {
        _showMessage(data['message'].toString(), error: true);
      } else if (response.statusCode == 200 || data == null) {
        _showMessage(
          'The server sent an unexpected response. Try again in a moment.',
          error: true,
        );
      } else {
        _showMessage('Email or password is incorrect.', error: true);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Can\'t reach the server. Check your connection and make sure Laravel is running.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    showAppSnack(context, message, error: error);
  }

  // ───────────────────────── DESIGN ONLY BELOW ─────────────────────────

  /// Soft decorative circle, like the reference background shapes.
  Widget _blob(double size, {double alpha = 40}) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.accent.withAlpha(alpha.toInt()),
            c.accentSoft.withAlpha(60),
          ],
        ),
        border: Border.all(color: c.accent.withAlpha(50), width: 1.5),
      ),
    );
  }

  /// Big rounded "glass" tile holding the current logo.
  Widget _logoTile() {
    final c = context.c;
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(56),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, c.accentSoft],
        ),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: c.accent.withAlpha(45),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      // Droplet only (no words)
      child: Center(
        child: Icon(Icons.water_drop_rounded, size: 116, color: c.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    // Fields + button inside a soft glass card
    final formCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface.withAlpha(215),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: c.accent.withAlpha(30),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppField(
              label: 'Email address',
              controller: _emailController,
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 20),
            AppField(
              label: 'Password',
              controller: _passwordController,
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _login(),
              suffix: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: c.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            // Glow under the button
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withAlpha(90),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: 60,
                child: PrimaryButton(
                label: 'Sign in',
                loading: _isLoading,
                onPressed: _login,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // Background: wave + soft circles
          const Positioned(top: 0, left: 0, right: 0, child: WaveBackdrop()),
          Positioned(top: -90, left: -90, child: _blob(240, alpha: 50)),
          Positioned(top: 170, right: -60, child: _blob(130, alpha: 35)),
          Positioned(bottom: -80, left: -70, child: _blob(180, alpha: 30)),
          Positioned(bottom: -100, right: -80, child: _blob(240, alpha: 40)),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 64),
                        child: Column(
                          children: [
                            // ── TOP: big logo + project name (centered) ──
                            _logoTile(),
                            const SizedBox(height: 20),
                            Text(
                              _appName,
                              textAlign: TextAlign.center,
                              style: t.label.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: c.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome back',
                              textAlign: TextAlign.center,
                              style: t.display,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Driver Login',
                              textAlign: TextAlign.center,
                              style: t.bodyMuted.copyWith(letterSpacing: 0.4),
                            ),

                            // Pushes everything below to the bottom
                            const Spacer(),
                            const SizedBox(height: 32),

                            // ── BOTTOM: fields + button ──
                            formCard,
                            const SizedBox(height: 20),

                            Text(
                              'No account yet? Ask the station admin to create one for you.',
                              textAlign: TextAlign.center,
                              style: t.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}