import 'package:shared_preferences/shared_preferences.dart';

class WorkerSession {
  static int? id;
  static String? name;
  static String? workerCode;

  static const String _workerIdKey = 'worker_id';
  static const String _workerNameKey = 'worker_name';
  static const String _workerCodeKey = 'worker_code';

  static Future<void> start({
    int? workerId,
    String? workerName,
    String? code,
  }) async {
    id = workerId;
    name = workerName;
    workerCode = code;

    final prefs = await SharedPreferences.getInstance();

    if (workerId != null) {
      await prefs.setInt(_workerIdKey, workerId);
    } else {
      await prefs.remove(_workerIdKey);
    }

    if (workerName != null && workerName.trim().isNotEmpty) {
      await prefs.setString(_workerNameKey, workerName);
    } else {
      await prefs.remove(_workerNameKey);
    }

    if (code != null && code.trim().isNotEmpty) {
      await prefs.setString(_workerCodeKey, code);
    } else {
      await prefs.remove(_workerCodeKey);
    }
  }

  static Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getInt(_workerIdKey);
    final savedName = prefs.getString(_workerNameKey);
    final savedCode = prefs.getString(_workerCodeKey);

    if (savedId == null) {
      id = null;
      name = null;
      workerCode = null;
      return false;
    }

    id = savedId;
    name = savedName;
    workerCode = savedCode;

    return true;
  }

  static Future<void> clear() async {
    id = null;
    name = null;
    workerCode = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_workerIdKey);
    await prefs.remove(_workerNameKey);
    await prefs.remove(_workerCodeKey);
  }

  static bool get isLoggedIn => id != null;

  static bool get isEmpty =>
      (name == null || name!.trim().isEmpty);

  static String get displayName {
    final n = name?.trim() ?? '';
    return n.isEmpty ? 'Worker' : n;
  }

  static String get firstName =>
      displayName.split(RegExp(r'\s+')).first;

  static String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'W';

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