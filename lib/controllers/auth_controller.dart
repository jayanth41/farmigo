import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore_user_service.dart';

/// Provider-based authentication controller that manages auth state,
/// login, signup, logout using Firebase Authentication with multiple auth methods.
/// Supports: Email/Password, Google Sign-In, Phone OTP
class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreUserService _firestoreService = FirestoreUserService();

  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _currentUser?.email;
  String? get userName => _userProfile?.name;
  String? get userPhone => _userProfile?.phone;
  String? get userPhotoUrl => _userProfile?.photoUrl;

  /// Initialize the authentication controller
  AuthController() {
    _initAuthListener();
  }

  /// Initialize auth state listener and load user profile
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _currentUser = user;
      _isAuthenticated = user != null;

      // Load user profile from Firestore if authenticated
      if (user != null) {
        _userProfile = await _firestoreService.getUserProfile(user.uid);
      } else {
        _userProfile = null;
      }

      notifyListeners();
      debugPrint(_isAuthenticated
          ? '✅ Auth: User logged in: ${user?.email}'
          : '❌ Auth: User logged out');
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
    String? name,
    String? phone,
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

      // Create user profile in Firestore
      if (_currentUser != null) {
        _userProfile = UserProfile(
          uid: _currentUser!.uid,
          email: email,
          name: name,
          phone: phone,
          loginType: 'email',
          createdAt: DateTime.now(),
        );
        await _firestoreService.saveUserProfile(_userProfile!);
      }

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

      // Load user profile from Firestore
      if (_currentUser != null) {
        _userProfile = await _firestoreService.getUserProfile(_currentUser!.uid);
      }

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

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _errorMessage = 'Google Sign-In cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Use both idToken and accessToken for v6 compatibility
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        _errorMessage = 'Failed to get Google Sign-In credentials';
        debugPrint('❌ No idToken from Google Sign-In');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      _currentUser = userCredential.user;
      _isAuthenticated = _currentUser != null;

      // Create or update user profile in Firestore
      if (_currentUser != null) {
        final profileExists =
            await _firestoreService.userProfileExists(_currentUser!.uid);

        if (profileExists) {
          _userProfile = await _firestoreService.getUserProfile(_currentUser!.uid);
        } else {
          _userProfile = UserProfile(
            uid: _currentUser!.uid,
            email: _currentUser!.email ?? '',
            name: _currentUser!.displayName,
            photoUrl: _currentUser!.photoURL,
            loginType: 'google',
            createdAt: DateTime.now(),
          );
          await _firestoreService.saveUserProfile(_userProfile!);
        }
      }

      debugPrint('✅ Google Sign-In success: ${_currentUser?.email}');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      debugPrint('❌ Google Sign-In error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed: $e';
      debugPrint('❌ Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Start phone number verification
  Future<bool> startPhoneNumberVerification(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto sign-in if verification is instant
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = _getFirebaseErrorMessage(e.code);
          debugPrint('❌ Phone verification failed: ${e.code} - ${e.message}');
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          debugPrint('✅ SMS code sent to $phoneNumber');
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('⏱️ Auto-retrieval timeout');
          _isLoading = false;
          notifyListeners();
        },
      );
      return true;
    } catch (e) {
      _errorMessage = 'Phone verification failed: $e';
      debugPrint('❌ Phone verification error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP code and sign in
  Future<bool> verifyOTPAndSignIn({
    required String otpCode,
    String? name,
    String? phoneNumber,
  }) async {
    if (_verificationId == null) {
      _errorMessage = 'Verification ID not found. Start verification first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      _currentUser = userCredential.user;
      _isAuthenticated = _currentUser != null;

      // Create or update user profile in Firestore
      if (_currentUser != null) {
        final profileExists =
            await _firestoreService.userProfileExists(_currentUser!.uid);

        if (profileExists) {
          _userProfile = await _firestoreService.getUserProfile(_currentUser!.uid);
        } else {
          _userProfile = UserProfile(
            uid: _currentUser!.uid,
            email: _currentUser!.email ?? '',
            name: name,
            phone: phoneNumber,
            loginType: 'phone',
            createdAt: DateTime.now(),
          );
          await _firestoreService.saveUserProfile(_userProfile!);
        }
      }

      _verificationId = null;
      debugPrint('✅ Phone Sign-In success: ${_currentUser?.phoneNumber}');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      debugPrint('❌ Phone Sign-In error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Phone Sign-In failed: $e';
      debugPrint('❌ Phone Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut(); // Also sign out from Google
      _currentUser = null;
      _userProfile = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _verificationId = null;
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
