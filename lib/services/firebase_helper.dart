import 'package:flutter/foundation.dart' show kIsWeb;
// no Flutter material imports required here

/// Lightweight helper to track whether Firebase successfully initialized.
///
/// This avoids throws when Firebase fails to init (emulator offline, DNS
/// failures). Code can check [FirebaseHelper.available] before calling
/// Firebase services.
class FirebaseHelper {
  static bool available = false;

  /// Called during app startup after attempting Firebase.initializeApp().
  static void setAvailable(bool v) => available = v;

  /// Safe guard: if running on web, assume availability (web handles it
  /// differently). Consumers should still catch exceptions on calls.
  static bool isLikelyAvailable() => available || kIsWeb;
}
