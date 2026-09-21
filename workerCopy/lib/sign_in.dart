import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_theme.dart';
import 'widgets.dart';
import 'worker_dashboard.dart';
import 'worker_session.dart';

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

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (!_validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/worker/login',
        ),
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

        // Remember who is signed in so every screen can show the real name.
        WorkerSession.start(
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
        showAppSnack(context, 'Worker ID or password is incorrect.', error: true);
      }
    } catch (e) {
      if (!mounted) return;

      showAppSnack(
        context,
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

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back', style: t.display),
          const SizedBox(height: 8),
          Text(
            "Sign in to manage today's wash bay operations.",
            style: t.bodyMuted,
          ),

          const SizedBox(height: 32),

          AppField(
            label: 'Worker ID',
            controller: _workerIdController,
            hint: 'Enter your Worker ID',
            icon: Icons.badge_outlined,
            error: _workerIdError,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onChanged: (_) {
              if (_workerIdError != null) {
                setState(() => _workerIdError = null);
              }
            },
          ),

          const SizedBox(height: 18),

          AppField(
            label: 'Password',
            controller: _passwordController,
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            error: _passwordError,
            obscure: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
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
            onPressed: _handleLogin,
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'Worker accounts are created by the administrator.',
              textAlign: TextAlign.center,
              style: t.caption,
            ),
          ),
        ],
      ),
    );
  }
}
