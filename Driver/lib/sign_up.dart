import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_theme.dart';
import 'login_driver.dart';
import 'widgets.dart';

class SignUpDriverScreen extends StatefulWidget {
  const SignUpDriverScreen({Key? key}) : super(key: key);

  @override
  State<SignUpDriverScreen> createState() => _SignUpDriverScreenState();
}

class _SignUpDriverScreenState extends State<SignUpDriverScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    showAppSnack(context, message, error: error);
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginDriverScreen()),
    );
  }

  Future<void> _signUp() async {
    if (_isLoading) return;

    // Get values from the text fields
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Basic validation
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Fill in all the required fields.', error: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords don\'t match.', error: true);
      return;
    }

    if (password.length < 8) {
      _showMessage('Use a password with at least 8 characters.', error: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine first and last name because the database
      // currently has one "name" column.
      final fullName = '$firstName $lastName';

      final response = await http.post(
        Uri.parse('http://192.168.100.236:8000/api/driver/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': fullName,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (!mounted) return;

      if (response.statusCode == 201) {
        _showMessage('Driver account created. You can sign in now.');

        // Go back to Driver Login
        _goToLogin();
      } else {
        String message = 'Couldn\'t create your account. Try again.';

        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }

        // Show Laravel validation errors if available
        if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;

          if (errors.isNotEmpty) {
            final firstError = errors.values.first;

            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            }
          }
        }

        _showMessage(message, error: true);
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

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    Widget eyeButton(bool obscured, VoidCallback onTap) {
      return IconButton(
        tooltip: obscured ? 'Show password' : 'Hide password',
        icon: Icon(
          obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: c.textMuted,
        ),
        onPressed: onTap,
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Stack(
            children: [
              const Positioned(top: 0, left: 0, right: 0, child: WaveBackdrop(height: 200)),
              Padding(
                padding: const EdgeInsets.all(24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandLockup(),

                      const SizedBox(height: 28),

                      // Sign in / Sign up switch
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _goToLogin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Sign in',
                                    style: t.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.accentSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: c.accent.withAlpha(140)),
                                ),
                                child: Text(
                                  'Sign up',
                                  style: t.label.copyWith(
                                    color: c.accent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Text('Create your account', style: t.display),
                      const SizedBox(height: 8),
                      Text(
                        'Set up your driver account to book truck washes.',
                        style: t.bodyMuted,
                      ),

                      const SizedBox(height: 26),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppField(
                              label: 'First name',
                              controller: _firstNameController,
                              capitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.givenName],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              label: 'Last name',
                              controller: _lastNameController,
                              capitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.familyName],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

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
                        label: 'Mobile number',
                        controller: _mobileController,
                        hint: '09123456789',
                        icon: Icons.smartphone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),

                      const SizedBox(height: 18),

                      AppField(
                        label: 'Password',
                        controller: _passwordController,
                        hint: 'At least 8 characters',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        suffix: eyeButton(_obscurePassword, () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }),
                      ),

                      const SizedBox(height: 18),

                      AppField(
                        label: 'Confirm password',
                        controller: _confirmPasswordController,
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signUp(),
                        suffix: eyeButton(_obscureConfirm, () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        }),
                      ),

                      const SizedBox(height: 28),

                      PrimaryButton(
                        label: 'Create account',
                        loading: _isLoading,
                        onPressed: _signUp,
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _goToLogin,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text.rich(
                              TextSpan(
                                text: 'Already have an account? ',
                                style: t.bodyMuted.copyWith(fontSize: 15),
                                children: [
                                  TextSpan(
                                    text: 'Sign in',
                                    style: t.body.copyWith(
                                      fontSize: 15,
                                      color: c.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
