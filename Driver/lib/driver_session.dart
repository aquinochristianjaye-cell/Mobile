import 'package:shared_preferences/shared_preferences.dart';

/// Holds who is signed in.
///
/// The Driver ID and name are also saved locally so the Driver
/// remains signed in after closing and reopening the app.
///
/// Cleared only when the Driver logs out.
class DriverSession {
  static int? id;
  static String? name;

  static const String _driverIdKey = 'driver_id';
  static const String _driverNameKey = 'driver_name';

  static Future<void> start({
    int? driverId,
    String? driverName,
  }) async {
    id = driverId;
    name = driverName;

    final prefs = await SharedPreferences.getInstance();

    if (driverId != null) {
      await prefs.setInt(_driverIdKey, driverId);
    } else {
      await prefs.remove(_driverIdKey);
    }

    if (driverName != null && driverName.trim().isNotEmpty) {
      await prefs.setString(_driverNameKey, driverName);
    } else {
      await prefs.remove(_driverNameKey);
    }
  }

  static Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getInt(_driverIdKey);
    final savedName = prefs.getString(_driverNameKey);

    if (savedId == null) {
      id = null;
      name = null;
      return false;
    }

    id = savedId;
    name = savedName;

    return true;
  }

  static Future<void> clear() async {
    id = null;
    name = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_driverIdKey);
    await prefs.remove(_driverNameKey);
  }

  static bool get isLoggedIn => id != null;

  static String get displayName {
    final n = name?.trim() ?? '';
    return n.isEmpty ? 'Driver' : n;
  }

  static String get firstName =>
      displayName.split(RegExp(r'\s+')).first;

  static String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'D';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (
      parts.first.substring(0, 1) +
      parts.last.substring(0, 1)
    ).toUpperCase();
  }

  static String get greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}