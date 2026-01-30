import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A minimal, no-dependency network checker.
/// Uses DNS lookup (InternetAddress.lookup) with a short timeout to
/// determine network availability. Returns true on web where DNS lookup
/// isn't applicable.
class NetworkUtils {
  /// Try to lookup a well-known host. Returns true if lookup succeeds.
  static Future<bool> hasNetwork({Duration timeout = const Duration(seconds: 3)}) async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('example.com').timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
