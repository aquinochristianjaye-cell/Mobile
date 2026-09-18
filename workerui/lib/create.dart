import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'main.dart';

class CreateAccountForm extends StatefulWidget {
  const CreateAccountForm({super.key, required this.onSwitchToSignIn});

  final VoidCallback onSwitchToSignIn;

  @override
  State<CreateAccountForm> createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _workerIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

Future<void> _handleCreateAccount() async {
  if (!(_formKey.currentState?.validate() ?? false)) {
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/worker/register'),
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
        'password_confirmation':
            _confirmPasswordController.text,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
        ),
      );

      widget.onSwitchToSignIn();
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message'] ?? 'Failed to create account',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot connect to the server'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create your account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set up access to the operations dashboard.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, innerConstraints) {
              final isNarrow = innerConstraints.maxWidth < 360;
              final firstNameField = buildLabeledField(
                label: 'First name',
                controller: _firstNameController,
                hint: 'Juan',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              );
              final lastNameField = buildLabeledField(
                label: 'Last Name',
                controller: _lastNameController,
                hint: 'Tamad',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    firstNameField,
                    const SizedBox(height: 16),
                    lastNameField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: firstNameField),
                  const SizedBox(width: 16),
                  Expanded(child: lastNameField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          buildLabeledField(
            label: 'Worker I.D',
            controller: _workerIdController,
            hint: 'Worker ID',
            icon: Icons.badge_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          buildLabeledField(
            label: 'Mobile Number',
            controller: _mobileController,
            hint: '09XXXXXXXXX',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length < 10) return 'Enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 16),

          buildLabeledField(
            label: 'Password',
            controller: _passwordController,
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          buildLabeledField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            onToggleObscure: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleCreateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.navy.withValues(alpha: 0.6),
                ),
                children: [
                  const TextSpan(text: 'Already have an Account?  '),
                  TextSpan(
                    text: 'Sign in',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = widget.onSwitchToSignIn,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}