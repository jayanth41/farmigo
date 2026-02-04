import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/snackbar_helper.dart';
import 'otp_screen.dart';
import 'home_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    var phone = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!phone.startsWith('+')) {
      if (phone.length == 10) phone = '+91$phone';
    }
    return phone;
  }

  Future<void> _startPhoneVerification() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      showAppSnack(context, 'Enter phone number', isError: true);
      return;
    }
    final phone = _normalizePhone(raw);
    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
            final user = userCred.user;
            if (user != null) {
              try {
                final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                final snap = await doc.get();
                if (!snap.exists) {
                  await doc.set({
                    'uid': user.uid,
                    'phone': user.phoneNumber ?? phone,
                    'provider': 'phone',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
              } catch (e) {
                debugPrint('Failed to create user doc after auto sign-in: $e');
              }

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
            }
          } catch (e) {
            debugPrint('Auto sign-in failed: $e');
            showAppSnack(context, 'Auto sign-in failed', isError: true);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.message}');
          showAppSnack(context, 'Verification failed: ${e.message}', isError: true);
          setState(() => _isSending = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OTPScreen(value: phone, verificationId: verificationId)),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      debugPrint('verifyPhoneNumber error: $e');
      showAppSnack(context, 'Failed to start phone verification', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Login with Phone'), backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: cs.onSurface)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text('Enter your phone number', style: txt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(hintText: 'Phone (e.g. +919876543210)', filled: true, fillColor: Theme.of(context).cardColor),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _startPhoneVerification,
                  child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
