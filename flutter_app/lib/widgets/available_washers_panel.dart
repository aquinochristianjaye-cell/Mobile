import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/worker_assignment_service.dart';
import '../services/worker_service.dart';
import 'common/panel.dart';

// ===================== AVAILABLE WASHERS =====================

class AvailableWashersPanel extends StatefulWidget {
  const AvailableWashersPanel({
    super.key,
  });

  @override
  State<AvailableWashersPanel> createState() =>
      _AvailableWashersPanelState();
}

class _AvailableWashersPanelState
    extends State<AvailableWashersPanel> {
  List<dynamic> assignments = [];
  List<Map<String, dynamic>> workers = [];

  Timer? _timer;

  // Worker form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _workerIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCreatingWorker = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    loadData();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadData();
      },
    );
  }

  Future<void> loadData() async {
    try {
      final activeAssignments =
          await WorkerAssignmentService.getActiveAssignments();

      final workerList =
          await WorkerService.getWorkers();

      if (!mounted) return;

      setState(() {
        assignments = activeAssignments;
        workers = workerList;
      });
    } catch (e) {
      // Keep dashboard working if API is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _workerIdController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ===================== CREATE WORKER POPUP =====================

  Future<void> _openCreateWorkerDialog() async {
    // Clear old values before opening.
    _firstNameController.clear();
    _lastNameController.clear();
    _workerIdController.clear();
    _mobileController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    _isCreatingWorker = false;
    _obscurePassword = true;
    _obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: !_isCreatingWorker,
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
                'Create Worker Account',
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
                        'Create an account for a wash station worker.',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // FIRST NAME
                      const Text(
                        'First Name',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _firstNameController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter first name',
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

                      // LAST NAME
                      const Text(
                        'Last Name',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _lastNameController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter last name',
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

                      // WORKER ID
                      const Text(
                        'Worker ID',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _workerIdController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Example: W-001',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
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

                      // MOBILE
                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _mobileController,
                        keyboardType:
                            TextInputType.phone,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter mobile number',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
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
                  onPressed: _isCreatingWorker
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
                  onPressed: _isCreatingWorker
                      ? null
                      : () async {
                          final firstName =
                              _firstNameController.text
                                  .trim();
                          final lastName =
                              _lastNameController.text
                                  .trim();
                          final workerId =
                              _workerIdController.text
                                  .trim();
                          final mobile =
                              _mobileController.text
                                  .trim();
                          final password =
                              _passwordController.text;
                          final confirmPassword =
                              _confirmPasswordController
                                  .text;

                          // Basic validation
                          if (firstName.isEmpty ||
                              lastName.isEmpty ||
                              workerId.isEmpty ||
                              mobile.isEmpty ||
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

                          if (password.length < 6) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password must be at least 6 characters.',
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
                            _isCreatingWorker = true;
                          });

                          try {
                            final response =
                                await http.post(
                              Uri.parse(
                                'http://127.0.0.1:8000/api/admin/workers',
                              ),
                              headers: {
                                'Accept':
                                    'application/json',
                              },
                              body: {
                                'first_name': firstName,
                                'last_name': lastName,
                                'worker_id': workerId,
                                'mobile': mobile,
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

                              await loadData();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Worker account created successfully.',
                                  ),
                                ),
                              );
                            } else {
                              setDialogState(() {
                                _isCreatingWorker = false;
                              });

                              String message =
                                  'Failed to create worker account.';

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
                              _isCreatingWorker = false;
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
                  child: _isCreatingWorker
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
                          'Create Worker',
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

  // ===================== RESET WORKER PASSWORD =====================

  Future<void> _openResetPasswordDialog(
    Map<String, dynamic> worker,
  ) async {
    final passwordController = TextEditingController();
    final confirmPasswordController =
        TextEditingController();

    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    bool isResetting = false;

    final workerDatabaseId = worker['id'];

    final firstName =
        worker['first_name']?.toString() ?? '';

    final lastName =
        worker['last_name']?.toString() ?? '';

    final workerName =
        '$firstName $lastName'.trim();

    await showDialog(
      context: context,
      barrierDismissible: !isResetting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: AppColors.panel,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              titlePadding:
                  const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                8,
              ),
              contentPadding:
                  const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                12,
              ),
              actionsPadding:
                  const EdgeInsets.fromLTRB(
                24,
                4,
                24,
                18,
              ),
              title: const Text(
                'Reset Worker Password',
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
                      Text(
                        workerName.isEmpty
                            ? 'Reset this worker\'s password.'
                            : 'Reset the password for $workerName.',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'The worker will be required to create a new permanent password after logging in.',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TEMPORARY PASSWORD
                      const Text(
                        'Temporary Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller:
                            passwordController,
                        obscureText:
                            obscurePassword,
                        enabled: !isResetting,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Enter temporary password',
                          hintStyle:
                              const TextStyle(
                            color:
                                AppColors.textFaint,
                          ),
                          prefixIcon:
                              const Icon(
                            Icons.lock_reset_outlined,
                            color:
                                AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed:
                                isResetting
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          obscurePassword =
                                              !obscurePassword;
                                        });
                                      },
                            icon: Icon(
                              obscurePassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color:
                                  AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              AppColors.panel2,
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(9),
                            borderSide:
                                BorderSide(
                              color:
                                  AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(9),
                            borderSide:
                                BorderSide(
                              color:
                                  AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(9),
                            borderSide:
                                const BorderSide(
                              color:
                                  AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // CONFIRM TEMPORARY PASSWORD
                      const Text(
                        'Confirm Temporary Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller:
                            confirmPasswordController,
                        obscureText:
                            obscureConfirmPassword,
                        enabled: !isResetting,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Confirm temporary password',
                          hintStyle:
                              const TextStyle(
                            color:
                                AppColors.textFaint,
                          ),
                          prefixIcon:
                              const Icon(
                            Icons.lock_outline,
                            color:
                                AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed:
                                isResetting
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          obscureConfirmPassword =
                                              !obscureConfirmPassword;
                                        });
                                      },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color:
                                  AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              AppColors.panel2,
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(9),
                            borderSide:
                                BorderSide(
                              color:
                                  AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(9),
                            borderSide:
                                BorderSide(
                              color:
                                  AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(9),
                            borderSide:
                                const BorderSide(
                              color:
                                  AppColors.water,
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
                  onPressed: isResetting
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                // RESET PASSWORD
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final password =
                              passwordController.text;

                          final confirmPassword =
                              confirmPasswordController
                                  .text;

                          if (password.isEmpty ||
                              confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill in both password fields.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password.length < 6) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Temporary password must be at least 6 characters.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password !=
                              confirmPassword) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Passwords do not match.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isResetting = true;
                          });

                          try {
                            final response =
                                await http.post(
                              Uri.parse(
                                'http://127.0.0.1:8000/api/admin/workers/$workerDatabaseId/reset-password',
                              ),
                              headers: {
                                'Accept':
                                    'application/json',
                              },
                              body: {
                                'password': password,
                                'password_confirmation':
                                    confirmPassword,
                              },
                            );

                            if (!mounted) return;

                            if (response.statusCode ==
                                200) {
                              Navigator.pop(
                                dialogContext,
                              );

                              await loadData();

                              if (!mounted) return;

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Worker password reset successfully. The worker must create a new password when logging in.',
                                  ),
                                ),
                              );
                            } else {
                              setDialogState(() {
                                isResetting = false;
                              });

                              String message =
                                  'Failed to reset worker password.';

                              if (response.body
                                  .isNotEmpty) {
                                message =
                                    response.body;
                              }

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(message),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isResetting = false;
                            });

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not connect to the server.\n$e',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.water,
                    foregroundColor:
                        AppColors.bg,
                    disabledBackgroundColor:
                        AppColors.water.withValues(
                      alpha: 0.4,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),
                  child: isResetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                AppColors.bg,
                          ),
                        )
                      : const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  // ===================== WORKER STATUS HELPERS =====================

  bool _isWorkerAvailable(
    Map<String, dynamic> worker,
  ) {
    final value = worker['is_available'];

    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  bool _isWorkerOnBreak(
    Map<String, dynamic> worker,
  ) {
    final value = worker['is_on_break'];

    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  @override
  Widget build(BuildContext context) {
    final busyWorkerIds = assignments
        .where(
          (assignment) =>
              assignment['status'] == 'assigned' ||
              assignment['status'] == 'washing',
        )
        .map(
          (assignment) => assignment['worker_id'],
        )
        .toSet();

    return Panel(
      eyebrow: 'Staff',
      title: 'Available Washers',

      // ADD WORKER BUTTON
      trailing: OutlinedButton.icon(
        onPressed: _openCreateWorkerDialog,
        icon: const Icon(
          Icons.person_add_outlined,
          size: 15,
        ),
        label: const Text(
          'Add Worker',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.water,
          side: BorderSide(
            color: AppColors.water.withValues(
              alpha: 0.35,
            ),
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8),
          ),
        ),
      ),

      // ===================== SCROLLABLE WORKER LIST =====================
      child: workers.isEmpty
          ? const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Text(
                'No workers available.',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                ),
              ),
            )
          : SizedBox(
              height: 130,
              child: ListView.builder(
                itemCount: workers.length,
                itemBuilder:
                    (context, index) {
                  final worker =
                      workers[index];

                  final workerId =
                      worker['id'];

                  final firstName =
                      worker['first_name']
                              ?.toString() ??
                          '';

                  final lastName =
                      worker['last_name']
                              ?.toString() ??
                          '';

                  final name =
                      '$firstName $lastName'
                          .trim();

                  final isAvailable =
                      _isWorkerAvailable(
                    worker,
                  );

                  final isOnBreak =
                      _isWorkerOnBreak(
                    worker,
                  );

                  final isOnWork =
                      busyWorkerIds.contains(
                    workerId,
                  );

                  // Priority:
                  // 1. On Work
                  // 2. On Break
                  // 3. Unavailable
                  // 4. Available
                  String status;
                  IconData icon;
                  Color statusColor;

                  if (isOnWork) {
                    status = 'ON WORK';
                    icon =
                        Icons.local_car_wash;
                    statusColor =
                        AppColors.crit;
                  } else if (isOnBreak) {
                    status = 'ON BREAK';
                    icon = Icons
                        .free_breakfast_outlined;
                    statusColor =
                        AppColors.warn;
                  } else if (!isAvailable) {
                    status = 'UNAVAILABLE';
                    icon = Icons.close;
                    statusColor =
                        AppColors.crit;
                  } else {
                    status = 'AVAILABLE';
                    icon = Icons.check;
                    statusColor =
                        AppColors.ok;
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: _WasherRow(
                      name: name.isEmpty
                          ? 'Unknown worker'
                          : name,
                      status: status,
                      icon: icon,
                      color: statusColor,
                      onResetPassword: () {
                        _openResetPasswordDialog(
                          worker,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// ===================== WASHER ROW =====================

class _WasherRow extends StatelessWidget {
  final String name;
  final String status;
  final IconData icon;
  final Color color;
  final VoidCallback onResetPassword;

  const _WasherRow({
    required this.name,
    required this.status,
    required this.icon,
    required this.color,
    required this.onResetPassword,
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
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 15,
              color: color,
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
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // RESET PASSWORD BUTTON
          Tooltip(
            message: 'Reset Password',
            child: IconButton(
              onPressed: onResetPassword,
              tooltip: 'Reset Password',
              icon: const Icon(
                Icons.lock_reset_outlined,
                size: 18,
                color: AppColors.water,
              ),
              visualDensity:
                  VisualDensity.compact,
              padding:
                  const EdgeInsets.all(5),
              constraints:
                  const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
            ),
          ),

          const SizedBox(width: 3),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(100),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

