import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'login_page.dart';

// Chrome / laptop. Use 10.0.2.2 for the Android emulator,
// or your PC's local IP for a real phone.
const String baseUrl = 'http://127.0.0.1:8000/api';

// Reads the best error message out of a Laravel JSON response.
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

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // REQUEST VERIFICATION CODE (used by register + resend)
  // Returns null on success, or an error message on failure.
  // ============================================================

  Future<String?> _requestCode() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        return null;
      }

      if (response.statusCode == 429) {
        return 'Too many requests. Please wait a minute and try again.';
      }

      return _extractMessage(
        jsonDecode(response.body),
        'Registration failed.',
      );
    } catch (e) {
      return 'Could not connect to the Laravel server.\n\n'
          'Make sure Laravel is running.';
    }
  }

  // ============================================================
  // REGISTER ACCOUNT (step 1: send code)
  // ============================================================

  Future<void> _registerAccount() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Basic Flutter-side validation
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final error = await _requestCode();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (error != null) {
      _showError(error);
      return;
    }

    _showVerifyDialog(email);
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width < 600) {
            return _buildMobileLayout();
          }

          if (width < 1000) {
            return _buildTabletLayout();
          }

          return _buildDesktopLayout();
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 105,
          child: _buildBrandPanel(),
        ),
        Expanded(
          flex: 100,
          child: _buildFormSide(),
        ),
      ],
    );
  }

  // ============================================================
  // TABLET
  // ============================================================

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 80,
          child: _buildBrandPanel(compact: true),
        ),
        Expanded(
          flex: 100,
          child: _buildFormSide(),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 30,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: _buildSignupForm(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BRANDING PANEL
  // ============================================================

  Widget _buildBrandPanel({
    bool compact = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12161D),
        border: Border(
          right: BorderSide(
            color: Color(0xFF232A35),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 32 : 56,
        vertical: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const Spacer(),
          _buildBrandMiddle(compact: compact),
          const Spacer(),
          _buildSystemStatus(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF22D3EE),
                Color(0xFF2DD4BF),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2DD4BF).withValues(alpha: .35),
                blurRadius: 20,
                spreadRadius: -6,
              ),
            ],
          ),
          child: const Icon(
            Icons.water_drop_outlined,
            color: Color(0xFF04151A),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Aquino Wash Station',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFE7EBF0),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'OPERATIONS DASHBOARD',
                style: TextStyle(
                  color: Color(0xFF5B6472),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandMiddle({
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Run the wash bays\nwithout the guesswork.',
          style: TextStyle(
            color: const Color(0xFFE7EBF0),
            fontSize: compact ? 26 : 32,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 360,
          ),
          child: const Text(
            'Live bay status, supply levels, and truck logs in one place — sign in to pick up where your shift left off.',
            style: TextStyle(
              color: Color(0xFF8B93A1),
              fontSize: 14.5,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatus() {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFF34D399),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34D399).withValues(alpha: .25),
                blurRadius: 8,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        const Flexible(
          child: Text(
            'DEVELOPED BY WONDERPETS',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF5B6472),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORM SIDE
  // ============================================================

  Widget _buildFormSide() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 40,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
          ),
          child: _buildSignupForm(),
        ),
      ),
    );
  }

  // ============================================================
  // CREATE ACCOUNT FORM
  // ============================================================

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create your account',
          style: TextStyle(
            color: Color(0xFFE7EBF0),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set up access to the operations dashboard.',
          style: TextStyle(
            color: Color(0xFF8B93A1),
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: _inputField(
                label: 'First name',
                controller: firstNameController,
                hint: 'Juan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                label: 'Last name',
                controller: lastNameController,
                hint: 'Aquino',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _inputField(
          label: 'Email address',
          controller: emailController,
          hint: 'you@aquinowash.com',
          icon: Icons.email_outlined,
        ),

        const SizedBox(height: 16),

        _inputField(
          label: 'Password',
          controller: passwordController,
          hint: 'Create a password',
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
          label: 'Confirm password',
          controller: confirmPasswordController,
          hint: 'Re-enter password',
          icon: Icons.lock_outline,
          obscure: obscureConfirmPassword,
          suffix: IconButton(
            onPressed: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF5B6472),
            ),
          ),
        ),

        const SizedBox(height: 22),

        _primaryButton(
          isLoading ? 'Sending code...' : 'Create account',
          isLoading ? () {} : _registerAccount,
        ),

        const SizedBox(height: 24),

        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(
                  color: Color(0xFF8B93A1),
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscure = false,
    Widget? suffix,
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
            keyboardType: label == 'Email address'
                ? TextInputType.emailAddress
                : TextInputType.text,
            style: const TextStyle(
              color: Color(0xFFE7EBF0),
              fontSize: 13.5,
            ),
            cursorColor: const Color(0xFF2DD4BF),
            decoration: InputDecoration(
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

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _primaryButton(
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          backgroundColor: const Color(0xFF2DD4BF),
          foregroundColor: const Color(0xFF04151A),
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

  // ============================================================
  // VERIFY CODE DIALOG
  // ============================================================

  void _showVerifyDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _VerifyCodeDialog(
          email: email,
          onResend: _requestCode,
          onVerified: () {
            if (!mounted) return;
            _showAccountCreatedDialog();
          },
        );
      },
    );
  }

  // ============================================================
  // ACCOUNT CREATED DIALOG
  // ============================================================

  void _showAccountCreatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171C25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF2DD4BF),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Account Created',
                style: TextStyle(
                  color: Color(0xFFE7EBF0),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your email has been verified and your account has been successfully created.',
            style: TextStyle(
              color: Color(0xFF8B93A1),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: const Color(0xFF04151A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Go to Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// VERIFY CODE DIALOG WIDGET
// ============================================================

class _VerifyCodeDialog extends StatefulWidget {
  final String email;
  final Future<String?> Function() onResend;
  final VoidCallback onVerified;

  const _VerifyCodeDialog({
    required this.email,
    required this.onResend,
    required this.onVerified,
  });

  @override
  State<_VerifyCodeDialog> createState() => _VerifyCodeDialogState();
}

class _VerifyCodeDialogState extends State<_VerifyCodeDialog> {
  static const int _cooldownSeconds = 30;

  final codeController = TextEditingController();

  bool isVerifying = false;
  bool isResending = false;
  String? errorText;
  String? infoText;

  int cooldown = _cooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    codeController.dispose();
    super.dispose();
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

  // ----------------------------------------------------------
  // VERIFY
  // ----------------------------------------------------------

  Future<void> _verify() async {
    final code = codeController.text.trim();

    if (code.length != 6) {
      setState(() {
        errorText = 'Please enter the 6-digit code.';
        infoText = null;
      });
      return;
    }

    setState(() {
      isVerifying = true;
      errorText = null;
      infoText = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/verify-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'code': code,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context);
        widget.onVerified();
        return;
      }

      String message;

      if (response.statusCode == 429) {
        message = 'Too many attempts. Please wait a minute and try again.';
      } else {
        message = _extractMessage(
          jsonDecode(response.body),
          'Verification failed.',
        );
      }

      setState(() {
        errorText = message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorText = 'Could not connect to the Laravel server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // RESEND
  // ----------------------------------------------------------

  Future<void> _resend() async {
    setState(() {
      isResending = true;
      errorText = null;
      infoText = null;
    });

    final error = await widget.onResend();

    if (!mounted) return;

    setState(() {
      isResending = false;

      if (error == null) {
        infoText = 'A new code has been sent to your email.';
        codeController.clear();
      } else {
        errorText = error;
      }
    });

    if (error == null) {
      _startCooldown();
    }
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final canResend = cooldown == 0 && !isResending && !isVerifying;

    return AlertDialog(
      backgroundColor: const Color(0xFF171C25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF2DD4BF),
            size: 28,
          ),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Verify your email',
              style: TextStyle(
                color: Color(0xFFE7EBF0),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We sent a 6-digit code to\n${widget.email}\n\nThe code expires in 5 minutes.',
              style: const TextStyle(
                color: Color(0xFF8B93A1),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF12161D),
                border: Border.all(
                  color: const Color(0xFF232A35),
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: TextField(
                controller: codeController,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (_) {
                  if (!isVerifying) _verify();
                },
                style: const TextStyle(
                  color: Color(0xFFE7EBF0),
                  fontSize: 24,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: const Color(0xFF2DD4BF),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    color: Color(0xFF5B6472),
                    letterSpacing: 10,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: const TextStyle(
                  color: Color(0xFFF87171),
                  fontSize: 13,
                ),
              ),
            ],
            if (infoText != null) ...[
              const SizedBox(height: 12),
              Text(
                infoText!,
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  isResending
                      ? 'Sending...'
                      : cooldown > 0
                          ? 'Resend code in ${cooldown}s'
                          : 'Resend code',
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: isVerifying ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF8B93A1)),
          ),
        ),
        ElevatedButton(
          onPressed: isVerifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2DD4BF),
            foregroundColor: const Color(0xFF04151A),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: isVerifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF04151A),
                  ),
                )
              : const Text(
                  'Verify',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}