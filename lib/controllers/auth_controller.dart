import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/supabase_config.dart';

/// Dual-provider AuthController
/// - Supabase: email OTP flows (send + verify)
/// - Firebase: phone OTP flows (verifyPhoneNumber + credential)
///
/// UI contract:
/// - loginWithEmail(email) -> sends email OTP via Supabase
/// - verifyEmailOtp(otp) -> verifies and signs in user, ensures Supabase `users` entry
/// - loginWithPhone(phone) -> starts Firebase phone verification (sends SMS)
/// - verifyPhoneOtp(otp) -> completes phone sign-in, ensures Supabase `users` entry
class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Phone verification state
  String? _verificationId;

  AuthController() {
    _init();
  }

  void _init() {
    // If a Firebase user already signed in, reflect that
    final user = _auth.currentUser;
    _isAuthenticated = user != null;
    // Listen for auth state changes
    _auth.authStateChanges().listen((u) {
      _isAuthenticated = u != null;
      notifyListeners();
    });
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------- Phone OTP (Firebase) ----------------------------------
  /// Send OTP to phone using Firebase
  // Phone (Firebase) entry point required by the new flow
  Future<bool> sendPhoneOTP(String phone) async {
    _errorMessage = null;
    if (phone.trim().isEmpty) {
      _errorMessage = 'Enter phone number';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    final completer = Completer<bool>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // Auto sign-in on some devices
          try {
            final userCred = await _auth.signInWithCredential(credential);
            final user = userCred.user;
            if (user != null) {
              await _createUserIfNotExists(user, provider: 'phone');
              _isAuthenticated = true;
              notifyListeners();
              if (!completer.isCompleted) completer.complete(true);
            } else {
              if (!completer.isCompleted) completer.complete(false);
            }
          } catch (e) {
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        verificationFailed: (e) {
          _errorMessage = e.message ?? 'Phone verification failed';
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );

      final res = await completer.future;
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  Future<bool> verifyPhoneOTP(String otp) async {
    _errorMessage = null;
    if (_verificationId == null) {
      _errorMessage = 'No verification in progress';
      notifyListeners();
      return false;
    }
    if (otp.trim().isEmpty) {
      _errorMessage = 'Enter OTP';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp.trim());
      final userCred = await _auth.signInWithCredential(cred);
      final user = userCred.user;
      if (user == null) {
        _errorMessage = 'Phone sign-in failed';
        notifyListeners();
        return false;
      }

      await _createUserIfNotExists(user, provider: 'phone');
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _verificationId = null;
      _setLoading(false);
    }
  }

  // Backwards-compatible aliases
  Future<bool> sendOTP(String phone) => sendPhoneOTP(phone);
  Future<bool> verifyOTP(String otp) => verifyPhoneOTP(otp);

  // ---------------- Email OTP (Supabase) ---------------------------------
  /// Sends an email OTP via Supabase (magic link / OTP depending on Supabase project)
  Future<bool> sendEmailOTP(String email) async {
    _errorMessage = null;
    if (email.trim().isEmpty) {
      _errorMessage = 'Enter email';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
  await supabase.Supabase.instance.client.auth.signInWithOtp(email: email.trim());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify email OTP via Supabase. The exact Supabase API may vary; this
  /// attempts to call verifyOtp which accepts email and token.
  Future<bool> verifyEmailOTP(String email, String otp) async {
    _errorMessage = null;
    if (otp.trim().isEmpty) {
      _errorMessage = 'Enter OTP';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      final url = Uri.parse('$SUPABASE_URL/auth/v1/verify');
      final res = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
          },
          body: jsonEncode({
            'type': 'signup',
            'email': email.trim(),
            'token': otp.trim(),
          }));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Verification failed (${res.statusCode})';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Backwards-compatible (deprecated) aliases for email OTP
  Future<bool> loginWithEmailOtp(String email) => sendEmailOTP(email);
  Future<bool> verifyEmailOtp(String email, String otp) => verifyEmailOTP(email, otp);

  // ---------------- shared helpers ----------------------------------------
  Future<void> _createUserIfNotExists(User user, {required String provider, String? name, String? phone}) async {
    try {
      final doc = _firestore.collection('users').doc(user.uid);
      final snapshot = await doc.get();
      if (snapshot.exists) return; // prevent duplicate creation

      final data = <String, dynamic>{
        'uid': user.uid,
        'name': name ?? user.displayName ?? '',
        'phone': phone ?? user.phoneNumber ?? '',
        'email': user.email ?? '',
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await doc.set(data);
    } catch (e) {
      debugPrint('Failed to create user document: $e');
    }
  }

  // ---------------- Logout -------------------------------------------------
  /// Backwards-compatible logout helper. Prefer calling [signOut].
  Future<void> logout() async {
    await signOut();
  }

  // ✅ Added signOut method as requested by the migration task. This is the
  // canonical logout method that UI callsites should use.
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();

    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}
