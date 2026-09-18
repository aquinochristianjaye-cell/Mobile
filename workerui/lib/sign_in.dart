import 'package:flutter/material.dart';
import 'main.dart';
import 'worker_dashboard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _workerIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _keepSignedIn = false;

  @override
  void dispose() {
    _workerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        final worker = data['worker'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome, ${worker['first_name']}!',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerDashboardScreen(
              workerId: worker['id'],
              workerName:
                  '${worker['first_name']} ${worker['last_name']}',
              workerIdNumber: worker['worker_id'],
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Invalid Worker ID or password',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot connect to the server',
          ),
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
            'Welcome Back!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Sign in to manage today's wash bay operations.",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          buildLabeledField(
            label: 'Worker I.D',
            controller: _workerIdController,
            hint: 'Worker ID',
            icon: Icons.mail_outline,
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
          ),
          const SizedBox(height: 16),

          buildLabeledField(
            label: 'Password',
            controller: _passwordController,
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            onToggleObscure: () => setState(
              () => _obscurePassword =
                  !_obscurePassword,
            ),
            validator: (v) =>
                (v == null || v.isEmpty)
                    ? 'Required'
                    : null,
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _keepSignedIn,
                      activeColor: AppColors.teal,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) => setState(
                        () => _keepSignedIn =
                            v ?? false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keep me signed in',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.navy
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'Worker accounts are created by the administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.navy
                    .withValues(alpha: 0.5),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

