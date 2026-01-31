import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase-only AuthController.
/// Exposes simple methods for email/password auth and minimal state for UI.
class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  AuthController() {
    _init();
  }

  void _init() {
    try {
      final client = supa.Supabase.instance.client;
      final user = client.auth.currentUser;
      _isAuthenticated = user != null;
      notifyListeners();

      // Listen for auth state changes
      client.auth.onAuthStateChange.listen((event) {
        try {
          final session = event.session;
          final user = session?.user;
          _isAuthenticated = user != null;
          notifyListeners();
        } catch (e) {
          // ignore listener errors but log
          debugPrint('Auth listener error: $e');
        }
      });
    } catch (e) {
      debugPrint('AuthController init error: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    if (email.trim().isEmpty) {
      _errorMessage = 'Enter email';
      notifyListeners();
      return false;
    }
    if (!email.contains('@')) {
      _errorMessage = 'Enter valid email';
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _errorMessage = 'Enter password';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final res = await supa.Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        // Try to extract friendly message from the response
        String msg = 'Invalid email or password';
        try {
          final dyn = res as dynamic;
          if (dyn.error != null && dyn.error.message != null) msg = dyn.error.message.toString();
        } catch (_) {}
        // Map common substrings to friendlier messages
        _errorMessage = _mapAuthErrorMessage(msg);
        return false;
      }

      _isAuthenticated = true;
      _errorMessage = null;
      return true;
    } catch (e) {
      final parsed = _mapAuthErrorMessage(e.toString());
      _errorMessage = parsed;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String email, String password) async {
    _errorMessage = null;
    if (email.trim().isEmpty) {
      _errorMessage = 'Enter email';
      notifyListeners();
      return false;
    }
    if (!email.contains('@')) {
      _errorMessage = 'Enter valid email';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final res = await supa.Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      // Check if signUp returned an error
      try {
        final dyn = res as dynamic;
        if (dyn.error != null) {
          _errorMessage = _mapAuthErrorMessage(dyn.error.message.toString());
          return false;
        }
      } catch (_) {}

      // If Supabase auto-signed in the user, mark as authenticated.
      final user = res.user;
      if (user != null) {
        _isAuthenticated = true;
        _errorMessage = null;
        return true;
      }

      // If signup succeeded but didn't auto sign-in, attempt to sign-in now.
      try {
        final signInRes = await supa.Supabase.instance.client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        if (signInRes.user != null) {
          _isAuthenticated = true;
          _errorMessage = null;
          return true;
        }
      } catch (e) {
        // fallthrough to success but unauthenticated (email verify flows)
      }

      // Signup succeeded but user must verify email; keep unauthenticated
      _isAuthenticated = false;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _mapAuthErrorMessage(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await supa.Supabase.instance.client.auth.signOut();
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapAuthErrorMessage(String raw) {
    final low = raw.toLowerCase();
    if (low.contains('network') || low.contains('socket')) return 'Network error — please check your connection';
    if (low.contains('invalid') || low.contains('credentials') || low.contains('invalid login')) return 'Invalid email or password';
    if (low.contains('password') && low.contains('incorrect')) return 'Password incorrect';
    if (low.contains('already') || low.contains('duplicate') || low.contains('user exists') || low.contains('email')) {
      // likely email already registered
      if (low.contains('password')) return 'Weak password or invalid password';
      return 'Email already exists';
    }
    // default fallback
    return raw;
  }

  // Backward-compatible aliases -------------------------------------------------
  // Keep existing login()/signup()/logout() logic unchanged; expose the older
  // method names so existing UI code continues to work.

  Future<bool> signIn({required String email, required String password}) {
    return login(email, password);
  }

  Future<bool> signUp({required String email, required String password, String? name, String? phone}) {
    // name/phone are accepted for compatibility but currently ignored by
    // the underlying signup(email,password) implementation.
    return signup(email, password);
  }

  Future<void> signOut() {
    return logout();
  }
}
