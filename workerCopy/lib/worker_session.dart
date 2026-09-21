/// Holds who is signed in, so screens can greet the worker by name and show
/// real initials instead of the hard-coded "Logan Miller" / "LM".
///
/// Set once in sign_in.dart, cleared on sign out.
class WorkerSession {
  static int? id;
  static String? name;
  static String? workerCode;

  static void start({int? workerId, String? workerName, String? code}) {
    id = workerId;
    name = workerName;
    workerCode = code;
  }

  static void clear() {
    id = null;
    name = null;
    workerCode = null;
  }

  static bool get isEmpty => (name == null || name!.trim().isEmpty);

  static String get displayName {
    final n = name?.trim() ?? '';
    return n.isEmpty ? 'Worker' : n;
  }

  static String get firstName => displayName.split(RegExp(r'\s+')).first;

  static String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'W';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
