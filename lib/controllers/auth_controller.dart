import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider-based authentication controller that manages auth state,
/// login, signup, logout using Firebase Authentication.
class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _currentUser?.email;

  AuthController() {
    _initAuthListener();
  }

  /// Initialize auth state listener
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _isAuthenticated = user != null;
      notifyListeners();
      debugPrint(_isAuthenticated ? '✅ Auth: User logged in: ${user?.email}' : '❌ Auth: User logged out');
    });
  }

  /// Check if user is currently authenticated
  Future<bool> checkAuthStatus() async {
    _currentUser = _auth.currentUser;
    _isAuthenticated = _currentUser != null;
    notifyListeners();
    return _isAuthenticated;
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _errorMessage = 'Please fill all fields';
      notifyListeners();
      return false;
    }

    if (!email.contains('@')) {
      _errorMessage = 'Enter a valid email';
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = userCredential.user;
      _isAuthenticated = _currentUser != null;

      debugPrint('✅ Signup success: ${_currentUser?.email}');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      debugPrint('❌ Signup error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Signup failed: $e';
      debugPrint('❌ Signup error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter email and password';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = userCredential.user;
      _isAuthenticated = _currentUser != null;

      debugPrint('✅ Login success: ${_currentUser?.email}');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      debugPrint('❌ Login error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      debugPrint('❌ Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      notifyListeners();
      debugPrint('✅ Logout success');
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
      debugPrint('❌ Logout error: $e');
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      _errorMessage = 'Please enter email';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later';
      default:
        return 'Authentication failed: $code';
    }
  }
}
