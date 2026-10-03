import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Chrome / laptop. Use 10.0.2.2 for the Android emulator,
// or your PC's local IP for a real phone.
const String _apiBase = 'http://127.0.0.1:8000/api';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int _cooldownSeconds = 30;

  // 0 = enter email, 1 = enter code + new password
  int step = 0;

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  String? errorText;
  String? infoText;

  int cooldown = 0;
  Timer? _timer;

  late final TextEditingController emailController;
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _extractMessage(dynamic data, String fallback) {
    String message = fallback;

    if (data is Map) {
      if (data['message'] != null) {
        message = data['message'].toString();
      }

      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;

        if (errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }
    }

    return message;
  }

  void _startCooldown() {
    _timer?.cancel();

    setState(() {
      cooldown = _cooldownSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (cooldown <= 1) {
        timer.cancel();
        setState(() {
          cooldown = 0;
        });
      } else {
        setState(() {
          cooldown--;
        });
      }
    });
  }

  // ============================================================
  // STEP 1: SEND CODE
  // ============================================================

  Future<void> _sendCode({bool isResend = false}) async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorText = 'Please enter your email address.';
        infoText = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
      infoText = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          step = 1;
          infoText = isResend
              ? 'A new code has been sent if that email is registered.'
              : null;
          codeController.clear();
        });
        _startCooldown();
      } else if (response.statusCode == 429) {
        setState(() {
          errorText = 'Too many requests. Please wait a minute and try again.';
        });
      } else {
        setState(() {
          errorText = _extractMessage(
            jsonDecode(response.body),
            'Could not send the code.',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorText =
            'Unable to connect to the server. Make sure Laravel is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 2: RESET PASSWORD
  // ============================================================

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (code.length != 6) {
      setState(() {
        errorText = 'Please enter the 6-digit code.';
        infoText = null;
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        errorText = 'Password must be at least 8 characters.';
        infoText = null;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        errorText = 'Passwords do not match.';
        infoText = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
      infoText = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': confirm,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. You can now sign in.'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
        return;
      }

      String message;

      if (response.statusCode == 429) {
        message = 'Too many attempts. Please wait a minute and try again.';
      } else {
        message = _extractMessage(
          jsonDecode(response.body),
          'Could not reset the password.',
        );
      }

      setState(() {
        errorText = message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorText =
            'Unable to connect to the server. Make sure Laravel is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: step == 0 ? _buildEmailStep() : _buildResetStep(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1 UI
  // ============================================================

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackLink('Back to sign in', () => Navigator.pop(context)),
        const SizedBox(height: 24),
        _buildHeader(
          icon: Icons.lock_reset_outlined,
          title: 'Forgot your password?',
          subtitle:
              "Enter your email and we'll send you a 6-digit code to reset it.",
        ),
        const SizedBox(height: 28),
        _inputField(
          label: 'Email address',
          controller: emailController,
          hint: 'you@aquinowash.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) {
            if (!isLoading) _sendCode();
          },
        ),
        _buildMessages(),
        const SizedBox(height: 22),
        _primaryButton(
          isLoading ? 'Sending code...' : 'Send reset code',
          isLoading ? null : _sendCode,
        ),
      ],
    );
  }

  // ============================================================
  // STEP 2 UI
  // ============================================================

  Widget _buildResetStep() {
    final canResend = cooldown == 0 && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackLink('Use a different email', () {
          _timer?.cancel();
          setState(() {
            step = 0;
            errorText = null;
            infoText = null;
            cooldown = 0;
          });
        }),
        const SizedBox(height: 24),
        _buildHeader(
          icon: Icons.mark_email_read_outlined,
          title: 'Reset your password',
          subtitle:
              'If ${emailController.text.trim()} is registered, we sent a 6-digit code. It expires in 5 minutes.',
        ),
        const SizedBox(height: 28),
        _inputField(
          label: 'Verification code',
          controller: codeController,
          hint: '••••••',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          digitsOnly: true,
        ),
        const SizedBox(height: 16),
        _inputField(
          label: 'New password',
          controller: passwordController,
          hint: 'At least 8 characters',
          icon: Icons.lock_outline,
          obscure: obscurePassword,
          suffix: IconButton(
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF5B6472),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _inputField(
          label: 'Confirm new password',
          controller: confirmController,
          hint: 'Re-enter new password',
          icon: Icons.lock_outline,
          obscure: obscureConfirm,
          onSubmitted: (_) {
            if (!isLoading) _resetPassword();
          },
          suffix: IconButton(
            onPressed: () {
              setState(() {
                obscureConfirm = !obscureConfirm;
              });
            },
            icon: Icon(
              obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF5B6472),
            ),
          ),
        ),
        _buildMessages(),
        const SizedBox(height: 22),
        _primaryButton(
          isLoading ? 'Resetting...' : 'Reset password',
          isLoading ? null : _resetPassword,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: canResend ? () => _sendCode(isResend: true) : null,
            child: Text(
              cooldown > 0 ? 'Resend code in ${cooldown}s' : 'Resend code',
              style: TextStyle(
                color: canResend
                    ? const Color(0xFF2DD4BF)
                    : const Color(0xFF5B6472),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildBackLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_back,
            size: 16,
            color: Color(0xFF8B93A1),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8B93A1),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF22D3EE),
                Color(0xFF2DD4BF),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF04151A),
            size: 22,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE7EBF0),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF8B93A1),
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMessages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null) ...[
          const SizedBox(height: 14),
          Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xFFF87171),
              fontSize: 13,
            ),
          ),
        ],
        if (infoText != null) ...[
          const SizedBox(height: 14),
          Text(
            infoText!,
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool digitsOnly = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B93A1),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF171C25),
            border: Border.all(
              color: const Color(0xFF232A35),
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLength: maxLength,
            onSubmitted: onSubmitted,
            inputFormatters: digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: const TextStyle(
              color: Color(0xFFE7EBF0),
              fontSize: 13.5,
            ),
            cursorColor: const Color(0xFF2DD4BF),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF5B6472),
                fontSize: 13.5,
              ),
              prefixIcon: icon == null
                  ? null
                  : Icon(
                      icon,
                      size: 17,
                      color: const Color(0xFF5B6472),
                    ),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          backgroundColor: const Color(0xFF2DD4BF),
          disabledBackgroundColor: const Color(0xFF2DD4BF),
          foregroundColor: const Color(0xFF04151A),
          disabledForegroundColor: const Color(0xFF04151A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF04151A),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}