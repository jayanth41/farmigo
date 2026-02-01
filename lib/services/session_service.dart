// SessionService is retained as a compatibility shim but guest-session
// semantics have been removed. All methods are no-ops to avoid changing
// app flow while ensuring any remaining calls continue to compile.
class SessionService {
  /// Deprecated: guest/session flags are removed. This is a no-op.
  static Future<void> setGuest(bool _) async {
    return;
  }

  /// Deprecated: always returns false (no guest sessions).
  static Future<bool> isGuest() async {
    return false;
  }

  /// Deprecated: no-op
  static Future<void> clear() async {
    return;
  }
}
