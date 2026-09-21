import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'app_theme.dart';
import 'widgets.dart';

class CreateAccountForm extends StatefulWidget {
  const CreateAccountForm({super.key, required this.onSwitchToSignIn});

  final VoidCallback onSwitchToSignIn;

  @override
  State<CreateAccountForm> createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<CreateAccountForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _workerIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _workerIdError;
  String? _mobileError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _workerIdController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final id = _workerIdController.text.trim();
    final mobile = _mobileController.text.trim();
    final pw = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    String? mobileErr;
    if (mobile.isEmpty) {
      mobileErr = 'Enter your mobile number.';
    } else if (mobile.length < 10) {
      mobileErr = 'Enter a valid mobile number.';
    }

    String? pwErr;
    if (pw.isEmpty) {
      pwErr = 'Enter a password.';
    } else if (pw.length < 6) {
      pwErr = 'Use at least 6 characters.';
    }

    String? confirmErr;
    if (confirm.isEmpty) {
      confirmErr = 'Re-enter your password.';
    } else if (confirm != pw) {
      confirmErr = 'Passwords don\'t match.';
    }

    setState(() {
      _firstNameError = first.isEmpty ? 'Enter your first name.' : null;
      _lastNameError = last.isEmpty ? 'Enter your last name.' : null;
      _workerIdError = id.isEmpty ? 'Enter your Worker ID.' : null;
      _mobileError = mobileErr;
      _passwordError = pwErr;
      _confirmError = confirmErr;
    });

    return first.isNotEmpty &&
        last.isNotEmpty &&
        id.isNotEmpty &&
        mobileErr == null &&
        pwErr == null &&
        confirmErr == null;
  }

  Future<void> _handleCreateAccount() async {
    if (_isLoading) return;

    if (!_validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.236:8000/api/worker/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'worker_id': _workerIdController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
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
        showAppSnack(context, 'Account created. You can sign in now.');

        widget.onSwitchToSignIn();
      } else {
        showAppSnack(
          context,
          (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Couldn\'t create your account. Try again.',
          error: true,
        );
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

  Widget _eye(bool obscured, VoidCallback onTap) {
    final c = context.c;
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: c.textMuted,
      ),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create your account', style: t.display),
          const SizedBox(height: 8),
          Text(
            'Set up access to the wash bay operations.',
            style: t.bodyMuted,
          ),

          const SizedBox(height: 26),

          LayoutBuilder(
            builder: (context, innerConstraints) {
              final isNarrow = innerConstraints.maxWidth < 360;
              final firstNameField = AppField(
                label: 'First name',
                controller: _firstNameController,
                hint: 'Juan',
                error: _firstNameError,
                capitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                onChanged: (_) {
                  if (_firstNameError != null) {
                    setState(() => _firstNameError = null);
                  }
                },
              );
              final lastNameField = AppField(
                label: 'Last name',
                controller: _lastNameController,
                hint: 'Tamad',
                error: _lastNameError,
                capitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                onChanged: (_) {
                  if (_lastNameError != null) {
                    setState(() => _lastNameError = null);
                  }
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    firstNameField,
                    const SizedBox(height: 18),
                    lastNameField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: firstNameField),
                  const SizedBox(width: 12),
                  Expanded(child: lastNameField),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          AppField(
            label: 'Worker ID',
            controller: _workerIdController,
            hint: 'Enter your Worker ID',
            icon: Icons.badge_outlined,
            error: _workerIdError,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_workerIdError != null) {
                setState(() => _workerIdError = null);
              }
            },
          ),

          const SizedBox(height: 18),

          AppField(
            label: 'Mobile number',
            controller: _mobileController,
            hint: '09XXXXXXXXX',
            icon: Icons.smartphone_rounded,
            error: _mobileError,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            autofillHints: const [AutofillHints.telephoneNumber],
            onChanged: (_) {
              if (_mobileError != null) {
                setState(() => _mobileError = null);
              }
            },
          ),

          const SizedBox(height: 18),

          AppField(
            label: 'Password',
            controller: _passwordController,
            hint: 'At least 6 characters',
            icon: Icons.lock_outline_rounded,
            error: _passwordError,
            obscure: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
            suffix: _eye(_obscurePassword, () {
              setState(() => _obscurePassword = !_obscurePassword);
            }),
          ),

          const SizedBox(height: 18),

          AppField(
            label: 'Confirm password',
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            icon: Icons.lock_outline_rounded,
            error: _confirmError,
            obscure: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleCreateAccount(),
            onChanged: (_) {
              if (_confirmError != null) {
                setState(() => _confirmError = null);
              }
            },
            suffix: _eye(_obscureConfirmPassword, () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            }),
          ),

          const SizedBox(height: 28),

          PrimaryButton(
            label: 'Create account',
            loading: _isLoading,
            onPressed: _handleCreateAccount,
          ),

          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSwitchToSignIn,
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
    );
  }
}
