import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          // Keeps the status bar icons readable in both themes.
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                  .copyWith(statusBarColor: Colors.transparent),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(), // Loads your splash screen on startup
        );
      },
    );
  }
}
