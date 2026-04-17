import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_sign_in;
import 'package:flutter/services.dart';
import '../services/user_bootstrap_service.dart';
import 'otp_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Reusable premium Google Sign-In button.
///
/// Usage: pass [onPressed] callback (nullable) and [isLoading] flag.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({super.key, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE0E0E0);

    final ButtonStyle style = OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      side: const BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      minimumSize: const Size.fromHeight(52),
    );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo asset on the left. Provide an errorBuilder fallback
            // so the UI remains intact if the asset isn't available at runtime.
            Image.asset(
              'assets/google_logo.png',
              height: 24,
              width: 24,
              fit: BoxFit.contain,
              semanticLabel: 'Google logo',
              errorBuilder: (context, error, stackTrace) {
                // Log the asset loading error to help debugging.
                debugPrint('Failed to load google_logo.png asset: $error');
                // Fallback: small colored 'G' badge to mimic Google mark.
                return Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            if (isLoading)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Flexible(
                child: Text(
                  'Continue with Google',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  bool _isValidPhone(String input) {
    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(input);
  }

  Future<void> sendPhoneOtp() async {
    final phone = phoneController.text.trim();
    FocusScope.of(context).unfocus();

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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
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
          Navigator.of(context).push(
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
    await g_sign_in.GoogleSignIn.instance.initialize();

    // Optional: sign out to force account chooser
    try {
      await g_sign_in.GoogleSignIn.instance.signOut();
    } catch (_) {}

    // Trigger interactive authentication
    final account = await g_sign_in.GoogleSignIn.instance.authenticate(
      scopeHint: ['email', 'profile'],
    );
    if (account == null) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
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
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Send OTP"),
              ),

              const SizedBox(height: 16),

              GoogleSignInButton(
                onPressed: isLoading ? null : () => signInWithGoogle(context),
                isLoading: isLoading,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}