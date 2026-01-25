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
Widget _tabButton(String text, bool active, {required VoidCallback onTap}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

Widget _inputField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool isPassword = false,
  TextInputType keyboard = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboard,
    obscureText: isPassword,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _primaryButton({
  required String text,
  required bool loading,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: const TextStyle(fontSize: 16)),
    ),
  );
}

Widget _socialBtn(IconData icon) {
  return Container(
    height: 48,
    width: 48,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon),
  );
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
    backgroundColor: const Color(0xFFF2F5F3),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // LOGO
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.park, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 16),

            const Text(
              "Farmigo",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              "Your Gateway to Perfect Getaways",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 30),

            // CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // LOGIN / SIGNUP TOGGLE
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _tabButton("Login", !useEmailLogin, onTap: () => setState(() => useEmailLogin = false)),
                        _tabButton("Email", useEmailLogin, onTap: () => setState(() => useEmailLogin = true)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (useEmailLogin) ...[
                    _inputField(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    _primaryButton(
                      text: "Login →",
                      loading: isLoading,
                      onTap: signInUser,
                    ),
                  ] else ...[
                    _inputField(
                      controller: phoneController,
                      hint: "Mobile Number",
                      icon: Icons.phone,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _primaryButton(
                      text: otpSent ? "Verify OTP" : "Send OTP",
                      loading: isLoading,
                      onTap: otpSent ? verifyOTP : sendOTP,
                    ),
                    if (otpSent) ...[
                      const SizedBox(height: 16),
                      _inputField(
                        controller: otpController,
                        hint: "Enter OTP",
                        icon: Icons.lock_outline,
                        keyboard: TextInputType.number,
                      ),
                    ]
                  ],

                  const SizedBox(height: 20),

                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("Or continue with"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _socialBtn(Icons.g_mobiledata),
                      _socialBtn(Icons.facebook),
                      _socialBtn(Icons.apple),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () => Get.toNamed('/signup'),
                    child: const Text("Sign up with email"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
TextButton(
  onPressed: () {
    Get.offAllNamed('/home');
  },
  child: const Text("Skip for now"),
),
          ],
        ),
      ),
    ),
  );
}

}
