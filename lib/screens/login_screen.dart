import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/user_bootstrap_service.dart';

import 'otp_screen.dart';
import 'home_screen.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  bool _isValidPhone(String input) {
    return RegExp(r'^[0-9]{10}$').hasMatch(input);
  }

  Future<void> sendPhoneOtp() async {
    final phone = phoneController.text.trim();

    if (!_isValidPhone(phone)) {
      setState(() {
        errorMessage = "Enter a valid 10-digit phone number";
      });
      return;
    }

    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phone",
        verificationCompleted: (credential) async {
          final cred = await FirebaseAuth.instance.signInWithCredential(credential);
          if (cred.user != null) {
            await UserBootstrapService.ensureUserDoc();
          }
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        verificationFailed: (e) {
          setState(() {
            errorMessage = e.message ?? "Phone verification failed";
            isLoading = false;
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            isLoading = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPScreen(
                value: phone,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

Future<void> signInWithGoogle(BuildContext context) async {
  setState(() {
    isLoading = true;
  });

  try {
    // google_sign_in v7.x uses singleton instance with initialize() + authenticate()
    // First, ensure the instance is initialized
    await GoogleSignIn.instance.initialize();

    // Optional: sign out to force account chooser
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    // Trigger interactive authentication
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: ['email', 'profile'],
    );
    if (account == null) return; // user cancelled

    // Get idToken from authentication (v7.x API)
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed: no idToken')),
      );
      return;
    }

    // Create Firebase credential with idToken only
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCred.user;

    if (user != null) {
      await UserBootstrapService.ensureUserDoc();
    }

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  } catch (e, st) {
    debugPrint('Google Sign-In error: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              const Text(
                "Login",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              const Text(
                "Phone number",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "", // BLANK placeholder as you asked
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 12),

              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: isLoading ? null : sendPhoneOtp,
                child: const Text("Send OTP"),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: isLoading ? null : () => signInWithGoogle(context),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text("Continue with Google"),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}