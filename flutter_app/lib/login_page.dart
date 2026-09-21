import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_account_page.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool keepSignedIn = false;
  bool obscurePassword = true;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.236:8000/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AquinoWashApp(),
          ),
        );
      } else {
        String message = 'Login failed.';

        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }

        if (mounted) {
          _showError(message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'Unable to connect to the server. Make sure Laravel is running.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Phone
          if (width < 600) {
            return _buildMobileLayout();
          }

          // Tablet / small desktop
          if (width < 1000) {
            return _buildTabletLayout();
          }

          // Large desktop
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
            child: _buildLoginForm(),
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
          _buildBrandMiddle(
            compact: compact,
          ),
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
                color: const Color(0xFF2DD4BF).withOpacity(.35),
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
                color: const Color(0xFF34D399).withOpacity(.25),
                blurRadius: 8,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        const Flexible(
          child: Text(
            'System online — Saturday, August 29, 2026',
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
            maxWidth: 380,
          ),
          child: _buildLoginForm(),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN FORM
  // ============================================================

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            color: Color(0xFFE7EBF0),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Sign in to manage today's wash bay operations.",
          style: TextStyle(
            color: Color(0xFF8B93A1),
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 28),

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
          hint: '••••••••••',
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

        const SizedBox(height: 4),

        _buildLoginOptions(),

        const SizedBox(height: 12),

        _primaryButton(
          isLoading ? 'Signing in...' : 'Sign in',
          isLoading ? () {} : _login,
        ),

        const SizedBox(height: 24),

        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              const Text(
                'New operator? ',
                style: TextStyle(
                  color: Color(0xFF8B93A1),
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateAccountPage(),
                    ),
                  );
                },
                child: const Text(
                  'Create an account',
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
  // LOGIN OPTIONS
  // ============================================================

  Widget _buildLoginOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Checkbox(
                value: keepSignedIn,
                onChanged: (value) {
                  setState(() {
                    keepSignedIn = value ?? false;
                  });
                },
                activeColor: const Color(0xFF2DD4BF),
                checkColor: const Color(0xFF04151A),
                side: const BorderSide(
                  color: Color(0xFF5B6472),
                ),
              ),
              const Flexible(
                child: Text(
                  'Keep me signed in',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8B93A1),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              color: Color(0xFF2DD4BF),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
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
                width: 20,
                height: 20,
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