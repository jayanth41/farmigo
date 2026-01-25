import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? verificationId;
  bool otpSent = false;
  bool useEmailLogin = false;
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> sendOTP() async {
    final phoneRaw = phoneController.text.trim();
    if (phoneRaw.isEmpty) {
      _showSnackBar('Enter a phone number');
      return;
    }

    String phone = phoneRaw.replaceAll(' ', '');
    if (!phone.startsWith('+')) {
      if (phone.length == 10) phone = '+91$phone';
    }

    setState(() => isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          if (mounted) {
            Get.offAllNamed('/home');
          }
        },
        verificationFailed: (e) {
          if (kDebugMode) debugPrint('verifyPhoneNumber failed: $e');
          _showSnackBar(e.message ?? 'Verification failed');
        },
        codeSent: (verId, _) {
          setState(() {
            verificationId = verId;
            otpSent = true;
          });
          _showSnackBar('OTP sent');
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('sendOTP error: $e');
      _showSnackBar('Failed to send OTP: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> verifyOTP() async {
    final code = otpController.text.trim();
    if (code.isEmpty || verificationId == null) {
      _showSnackBar('Enter OTP');
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: code,
      );
      await _auth.signInWithCredential(credential);
      if (mounted) Get.offAllNamed('/home');
    } catch (e) {
      if (kDebugMode) debugPrint('verifyOTP error: $e');
      _showSnackBar('OTP verification failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signInUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user != null) {
        if (kDebugMode) debugPrint('Login success: ${user.email}');
        if (mounted) {
          _showSnackBar('Login successful');
          Get.offAllNamed('/home');
        }
      } else {
        _showSnackBar('Login failed - check credentials');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      _showSnackBar('Login failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome 👋',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Login to continue', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => useEmailLogin = !useEmailLogin),
                  child: Text(useEmailLogin ? 'Use phone login' : 'Use email login'),
                ),
              ),

              if (useEmailLogin) ...[
                TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signInUser,
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login with email'),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const Text('Mobile Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), child: const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: phoneController, keyboardType: TextInputType.phone, maxLength: 10, decoration: InputDecoration(counterText: '', hintText: 'Enter mobile number', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : sendOTP,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                if (otpSent) ...[
                  TextField(controller: otpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Enter OTP')),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: isLoading ? null : verifyOTP, child: const Text('Verify OTP')),
                  ),
                ],
              ],

              const SizedBox(height: 12),
              TextButton(onPressed: () => Get.toNamed('/signup'), child: const Text('Sign up with email')),
            ],
          ),
        ),
      ),
    );
  }
}
