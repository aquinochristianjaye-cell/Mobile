/// Holds who is signed in, so screens can greet the driver by name and show
/// real initials instead of the hard-coded "Logan" / "LM".
///
/// Set once in login_driver.dart, cleared on sign out.
class DriverSession {
  static int? id;
  static String? name;

  static void start({int? driverId, String? driverName}) {
    id = driverId;
    name = driverName;
  }

  static void clear() {
    id = null;
    name = null;
  }

  static String get displayName {
    final n = name?.trim() ?? '';
    return n.isEmpty ? 'Driver' : n;
  }

  static String get firstName => displayName.split(RegExp(r'\s+')).first;

  static String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'D';
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
