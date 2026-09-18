import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateWorkerPage extends StatefulWidget {
  const CreateWorkerPage({super.key});

  @override
  State<CreateWorkerPage> createState() => _CreateWorkerPageState();
}

class _CreateWorkerPageState extends State<CreateWorkerPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _workerIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color background = Color(0xFF080B0D);
  static const Color panel = Color(0xFF101518);
  static const Color panel2 = Color(0xFF151B1F);
  static const Color line = Color(0xFF273137);
  static const Color textPrimary = Color(0xFFF2F5F6);
  static const Color textSecondary = Color(0xFF9AA8AE);
  static const Color teal = Color(0xFF16D9C5);

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

  Future<void> _createWorker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/admin/workers',
        ),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'worker_id': _workerIdController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation':
              _confirmPasswordController.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: panel,
              title: const Text(
                'Worker Account Created',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'The worker account has been created successfully.',
                style: TextStyle(
                  color: textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        String message =
            'Failed to create worker account.';

        if (response.body.isNotEmpty) {
          message = response.body;
        }

        _showError(message);
      }
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not connect to the server.\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: panel,
          title: const Text(
            'Error',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        color: textSecondary,
        size: 19,
      ),
      filled: true,
      fillColor: panel2,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: line,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: teal,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  String? _requiredValidator(
    String? value,
    String field,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: line,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                            icon: const Icon(
                              Icons.arrow_back,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Create Worker Account',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Padding(
                        padding:
                            EdgeInsets.only(left: 12),
                        child: Text(
                          'Create an account for a wash station worker.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'First Name',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _firstNameController,
                        style: const TextStyle(
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Enter first name',
                          icon: Icons.person_outline,
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'First name',
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Last Name',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _lastNameController,
                        style: const TextStyle(
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Enter last name',
                          icon: Icons.person_outline,
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'Last name',
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Worker ID',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _workerIdController,
                        style: const TextStyle(
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Example: W-001',
                          icon: Icons.badge_outlined,
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'Worker ID',
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _mobileController,
                        keyboardType:
                            TextInputType.phone,
                        style: const TextStyle(
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Enter mobile number',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'Mobile number',
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Password',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: textPrimary,
                        ),
                        decoration:
                            _inputDecoration(
                          hint: 'Enter password',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Password is required';
                          }

                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller:
                            _confirmPasswordController,
                        obscureText:
                            _obscureConfirmPassword,
                        style: const TextStyle(
                          color: textPrimary,
                        ),
                        decoration:
                            _inputDecoration(
                          hint: 'Confirm password',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please confirm the password';
                          }

                          if (value !=
                              _passwordController.text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _createWorker,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor:
                                background,
                            disabledBackgroundColor:
                                teal.withOpacity(0.4),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: background,
                                  ),
                                )
                              : const Text(
                                  'Create Worker Account',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Back to Dashboard',
                          style: TextStyle(
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}