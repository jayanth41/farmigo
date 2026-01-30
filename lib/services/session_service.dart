import 'package:shared_preferences/shared_preferences.dart';

/// Simple session helper to mark a guest session and clear it on logout.
///
/// This is intentionally tiny to avoid changing app flow. It provides a
/// single source of truth for a "guest" flag so multiple places can check
/// whether the current session is a guest session.
class SessionService {
  static const _kIsGuest = 'is_guest_session';

  /// Mark/unmark guest session.
  static Future<void> setGuest(bool isGuest) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kIsGuest, isGuest);
  }

  /// Returns whether the current stored session is a guest session.
  static Future<bool> isGuest() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kIsGuest) ?? false;
  }

  /// Clear guest flag (used during logout)
  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kIsGuest);
  }
}
