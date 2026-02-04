
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'otp_screen.dart';
import 'home_screen.dart';

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
          await FirebaseAuth.instance.signInWithCredential(credential);
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
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    // This line makes Google show all accounts every time 👇
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser =
        await googleSignIn.signIn();

    if (googleUser == null) return; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  } catch (e) {
    debugPrint("Google Sign-In Error: $e");
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
