import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const WashStationApp());
}

class WashStationApp extends StatelessWidget {
  const WashStationApp({super.key});

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
      home: const LoginPage(),
    );
  }
}

