import 'package:flutter/material.dart';

import 'admin_session.dart';
import 'login_page.dart';
import 'widgets/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await AdminSession.restore();

  runApp(
    WashStationApp(
      isLoggedIn: isLoggedIn,
    ),
  );
}

class WashStationApp extends StatelessWidget {
  final bool isLoggedIn;

  const WashStationApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aquino Wash Station',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2DD4BF),
          brightness: Brightness.dark,
        ),
      ),
      home: isLoggedIn
          ? const DashboardScreen()
          : const LoginPage(),
    );
  }
}