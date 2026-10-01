import 'package:shared_preferences/shared_preferences.dart';

class AdminSession {
  static bool isLoggedIn = false;
  static String? email;

  static const String _loggedInKey = 'admin_logged_in';
  static const String _emailKey = 'admin_email';

  static Future<void> start({
    required String adminEmail,
  }) async {
    isLoggedIn = true;
    email = adminEmail;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_emailKey, adminEmail);
  }

  static Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLogin = prefs.getBool(_loggedInKey) ?? false;
    final savedEmail = prefs.getString(_emailKey);

    if (!savedLogin) {
      isLoggedIn = false;
      email = null;
      return false;
    }

    isLoggedIn = true;
    email = savedEmail;

    return true;
  }

  static Future<void> clear() async {
    isLoggedIn = false;
    email = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_loggedInKey);
    await prefs.remove(_emailKey);
  }
}