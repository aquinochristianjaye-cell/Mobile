import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/driver_service.dart';
import 'common/panel.dart';

/// ===================== DRIVERS =====================
class DriversPanel extends StatefulWidget {
  const DriversPanel({super.key});

  @override
  State<DriversPanel> createState() =>
      _DriversPanelState();
}

class _DriversPanelState
    extends State<DriversPanel> {
  List<dynamic> drivers = [];

  Timer? _timer;

  // Driver form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController();

  bool _isCreatingDriver = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _loadDrivers();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadDrivers();
      },
    );
  }

  Future<void> _loadDrivers() async {
    try {
      final data =
          await DriverService.getDrivers();

      if (!mounted) return;

      setState(() {
        drivers = data;
      });
    } catch (e) {
      // Keep the current driver list if API is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ===================== CREATE DRIVER POPUP =====================

  Future<void> _openCreateDriverDialog() async {
    // Clear old values before opening.
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    _isCreatingDriver = false;
    _obscurePassword = true;
    _obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: !_isCreatingDriver,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                12,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                24,
                4,
                24,
                18,
              ),
              title: const Text(
                'Create Driver Account',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create an account for a driver.',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // NAME
                      const Text(
                        'Name',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter driver name',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // EMAIL
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // PASSWORD
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // CONFIRM PASSWORD
                      const Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller:
                            _confirmPasswordController,
                        obscureText:
                            _obscureConfirmPassword,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Confirm password',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // CANCEL
                TextButton(
                  onPressed: _isCreatingDriver
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // CREATE
                ElevatedButton(
                  onPressed: _isCreatingDriver
                      ? null
                      : () async {
                          final name =
                              _nameController.text.trim();
                          final email =
                              _emailController.text.trim();
                          final password =
                              _passwordController.text;
                          final confirmPassword =
                              _confirmPasswordController
                                  .text;

                          // Basic validation
                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill in all fields.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!email.contains('@')) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid email address.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password.length < 8) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password must be at least 8 characters.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Passwords do not match.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            _isCreatingDriver = true;
                          });

                          try {
                            final response =
                                await http.post(
                              Uri.parse(
                                'http://127.0.0.1:8000/api/admin/drivers',
                              ),
                              headers: {
                                'Accept':
                                    'application/json',
                              },
                              body: {
                                'name': name,
                                'email': email,
                                'password': password,
                                'password_confirmation':
                                    confirmPassword,
                              },
                            );

                            if (!mounted) return;

                            if (response.statusCode == 201) {
                              Navigator.pop(
                                dialogContext,
                              );

                              await _loadDrivers();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Driver account created successfully.',
                                  ),
                                ),
                              );
                            } else {
                              setDialogState(() {
                                _isCreatingDriver = false;
                              });

                              String message =
                                  'Failed to create driver account.';

                              if (response.body.isNotEmpty) {
                                message = response.body;
                              }

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              _isCreatingDriver = false;
                            });

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not connect to the server.\n$e',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.water,
                    foregroundColor: AppColors.bg,
                    disabledBackgroundColor:
                        AppColors.water.withValues(alpha: 0.4),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCreatingDriver
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bg,
                          ),
                        )
                      : const Text(
                          'Create Driver',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      eyebrow: 'Staff',
      title: 'Drivers',

      // ADD DRIVER BUTTON
      trailing: OutlinedButton.icon(
        onPressed: _openCreateDriverDialog,
        icon: const Icon(
          Icons.person_add_outlined,
          size: 15,
        ),
        label: const Text(
          'Add Driver',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.water,
          side: BorderSide(
            color: AppColors.water.withValues(alpha: 0.35),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      child: drivers.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 30,
                    color: AppColors.textFaint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No driver accounts',
                    style: bodyStyle(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: drivers.length > 2
                  ? 100
                  : null,
              child: Scrollbar(
                thumbVisibility:
                    drivers.length > 2,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: drivers.length > 2
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: drivers.length,
                  itemBuilder:
                      (context, index) {
                    final driver =
                        drivers[index];

                    final name =
                        driver['name']
                                ?.toString() ??
                            'Unknown driver';

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: _DriverRow(
                        name: name,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// ===================== DRIVER ROW =====================

class _DriverRow extends StatelessWidget {
  final String name;

  const _DriverRow({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  AppColors.water.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 15,
              color: AppColors.water,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              name,
              style: bodyStyle(
                size: 12.5,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

