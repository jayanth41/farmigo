import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// theme colors are used from Theme.of(context).colorScheme
import '../widgets/snackbar_helper.dart';
// routes used via literal strings where needed
import 'otp_screen.dart';
import 'home_screen.dart';
import '../navigation/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  bool _isGoogleLoading = false;

  void _showSnackBar(String msg, {bool error = true}) {
    showAppSnack(context, msg, isError: error);
  }

  void _sendOtp() {
    final value = _identifierController.text.trim();
    if (value.isEmpty) {
      _showSnackBar('Enter email or phone');
      return;
    }

    // Decide whether input is email or phone
    if (value.contains('@')) {
      // Email login should not display OTP. Guide user to email/password flow
      // or social sign-in. Do not navigate to OTP for emails.
      _showSnackBar('Email login is handled via email/password flow. Use Sign up or Google to continue.', error: false);
      return;
    }

    // treat as phone
    var phone = value;
    final digits = RegExp(r'^[0-9]+$');
    if (!digits.hasMatch(phone) || phone.length < 7) {
      _showSnackBar('Enter a valid phone number');
      return;
    }

    if (!phone.startsWith('+')) {
      // assume local +91 if 10 digits
      if (phone.length == 10) phone = '+91$phone';
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OTPScreen(value: phone, authType: AuthType.phone)),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final google = GoogleSignIn(scopes: ['email']);

      // Attempt a silent sign-in first to avoid extra prompts when possible
      GoogleSignInAccount? account = await google.signInSilently();
      account ??= await google.signIn();

      if (account == null) {
        // user cancelled or Google Sign-In not configured
        showAppSnack(context, 'Google Sign-In not configured or cancelled', isError: true);
        return;
      }

      final auth = await account.authentication;

      // Ensure we have at least one token; missing tokens usually indicate config issues
      if ((auth.idToken == null || auth.idToken!.isEmpty) && (auth.accessToken == null || auth.accessToken!.isEmpty)) {
        showAppSnack(context, 'Google didn\'t return credentials — check OAuth client ID & SHA fingerprints in Firebase Console', isError: true);
        return;
      }

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken);
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
          if (user == null) {
            showAppSnack(context, 'Google Sign-In failed', isError: true);
            return;
          }

      // Ensure a user document exists in Firestore (non-destructive)
      try {
        final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snap = await doc.get();
        if (!snap.exists) {
          await doc.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'provider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Failed to create user doc after Google sign-in: $e');
      }

  // Navigate to home on success and clear the previous routes so back doesn't return to Login
  if (!mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (route) => false,
  );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google sign-in: $e');
      showAppSnack(context, 'Google Sign-In failed: ${e.message ?? e.code}', isError: true);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      showAppSnack(context, 'Google Sign-In not configured or failed. Ensure Google is enabled in Firebase and OAuth client IDs / SHA fingerprints are set.', isError: true);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // user icon
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: cs.onBackground.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(child: Icon(Icons.person, size: 48, color: cs.primary)),
                ),
                const SizedBox(height: 20),
                Text('Welcome Back', style: txt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Sign in to continue to your account', style: txt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                const SizedBox(height: 24),

                // Input
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Email or Phone number',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Send OTP gradient button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Material(
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _sendOtp,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.9)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                        ),
                        child: Center(child: Text('Send OTP', style: txt.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                Row(children: [Expanded(child: Divider(color: Theme.of(context).dividerColor)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: txt.bodySmall)), Expanded(child: Divider(color: Theme.of(context).dividerColor))]),
                const SizedBox(height: 16),

                // Social buttons
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                          icon: _isGoogleLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.g_mobiledata, color: Colors.red),
                          label: _isGoogleLoading ? const Text('Signing in...') : const Text('Google', style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showSnackBar('Apple sign-in not configured', error: false);
                          },
                          icon: const Icon(Icons.apple, size: 20, color: Colors.white),
                          label: const Text('Apple', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
