import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'sign_in.dart';
import 'worker_dashboard.dart';
import 'worker_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await WorkerSession.restore();

  runApp(
    AquinoWashStationApp(
      isLoggedIn: isLoggedIn,
    ),
  );
}

class AquinoWashStationApp extends StatelessWidget {
  final bool isLoggedIn;

  const AquinoWashStationApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Aquino Wash Station',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,

          builder: (context, child) {
            final isDark =
                Theme.of(context).brightness == Brightness.dark;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: (isDark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                statusBarColor: Colors.transparent,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },

          home: isLoggedIn
              ? WorkerDashboardScreen(
                  workerId: WorkerSession.id!,
                  workerName: WorkerSession.displayName,
                  workerIdNumber: WorkerSession.workerCode ?? '',
                )
              : const AuthScreen(),
        );
      },
    );
  }
}

/// The login screen is now just the redesigned SignInForm:
/// no BrandLockup, no WaveBackdrop, no scroll view.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08141C), // matches the new design
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const SignInForm(),
          ),
        ),
      ),
    );
  }
}