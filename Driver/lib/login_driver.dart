import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_theme.dart';
import 'dashboard_driver.dart';
import 'driver_session.dart';
import 'widgets.dart';

class LoginDriverScreen extends StatefulWidget {
  const LoginDriverScreen({Key? key}) : super(key: key);

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
        DriverSession.start(
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

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              const Positioned(top: 0, left: 0, right: 0, child: WaveBackdrop()),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandLockup(),

                      const SizedBox(height: 64),

                      Text('Welcome back', style: t.display),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with the account your station admin gave you.',
                        style: t.bodyMuted,
                      ),

                      const SizedBox(height: 32),

                      AppField(
                        label: 'Email address',
                        controller: _emailController,
                        hint: 'name@example.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                      ),

                      const SizedBox(height: 18),

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

                      const SizedBox(height: 28),

                      PrimaryButton(
                        label: 'Sign in',
                        loading: _isLoading,
                        onPressed: _login,
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'No account yet? Ask the station admin to create one for you.',
                          textAlign: TextAlign.center,
                          style: t.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
