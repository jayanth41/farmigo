import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Email OTP flows via a third party are not supported here. This
// controller uses Firebase Authentication for phone OTP and Google Sign-In.

/// AuthController
/// - Firebase: phone OTP flows (verifyPhoneNumber + credential) and Google Sign-In
///
/// UI contract:
/// - loginWithEmail(email) -> NOT SUPPORTED (email OTP not implemented)
/// - verifyEmailOtp(otp) -> NOT SUPPORTED
/// - loginWithPhone(phone) -> starts Firebase phone verification (sends SMS)
/// - verifyPhoneOtp(otp) -> completes phone sign-in and creates Firestore profile
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

  // ---------------- Email OTP (not supported) -------------------------------
  /// Email OTP via an external provider is not supported in this build.
  /// Use phone OTP or Google Sign-In instead.
  Future<bool> sendEmailOTP(String email) async {
    // Email OTP flows were intentionally removed from the app during the
    // migration to Firebase-only auth. The UI paths no longer route emails
    // into the OTP flow; therefore this method simply returns false without
    // setting a user-visible error message to avoid surfacing 'not supported'
    // messages from deep call sites.
    _errorMessage = null;
    notifyListeners();
    return false;
  }

  /// Verify email OTP (not supported in this migration).
  Future<bool> verifyEmailOTP(String email, String otp) async {
    // Email OTP verification no longer supported; return false quietly.
    _errorMessage = null;
    notifyListeners();
    return false;
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
