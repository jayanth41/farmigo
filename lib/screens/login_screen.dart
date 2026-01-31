import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// theme colors are used from Theme.of(context).colorScheme
import '../controllers/auth_controller.dart';
import '../widgets/snackbar_helper.dart';
import '../services/session_service.dart';
import '../navigation/app_routes.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _useEmailLogin = false;

  // ---------------- SEND OTP ----------------
  Future<void> _sendOTP() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      _showSnackBar('Enter valid 10-digit mobile number');
      return;
    }

    // Phone OTP flow not implemented in Supabase-only controller in this
    // refactor. Prompt user to use email login.
    _showSnackBar('Phone login is not available. Please use email login.');
    return;

    // If you later implement phone OTP via Supabase, call that method here and
    // navigate to OTPScreen on success. For now we simply return above.
  }

  // EMAIL LOGIN using Supabase
  Future<void> _signInWithEmailViaAuth(
      BuildContext context, String email, String password) async {
    final auth = context.read<AuthController>();

    // Client-side validation
    if (email.trim().isEmpty) {
      _showSnackBar('Enter email');
      return;
    }
    if (!email.contains('@')) {
      _showSnackBar('Enter valid email');
      return;
    }
    if (password.isEmpty) {
      _showSnackBar('Enter password');
      return;
    }

    // Call controller
    final success = await auth.signIn(email: email.trim(), password: password);
    if (!mounted) return;

        if (success) {
          showAppSnack(context, 'Login successful', isSuccess: true);
          // Clear password from controller for safety
          passwordController.clear();
          // Navigate to Home and clear stack
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        } else {
      final msg = auth.errorMessage ?? 'Login failed';
      showAppSnack(context, msg, isError: true);
      // If likely invalid credentials, clear password field
      if (msg.toLowerCase().contains('invalid') || msg.toLowerCase().contains('password')) {
        passwordController.clear();
      }
    }
  }

  void _showSnackBar(String msg) {
    showAppSnack(context, msg, isError: true);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final txt = Theme.of(context).textTheme;
  final auth = Provider.of<AuthController>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Text(
                  'Welcome 👋',
                  style: txt.titleLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue',
                  style: txt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 40),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _useEmailLogin = !_useEmailLogin),
                    child: Text(
                      _useEmailLogin ? 'Use phone login' : 'Use email login',
                      style: TextStyle(color: cs.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (!_useEmailLogin) ...[
                  const Text('Mobile Number'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('+91', style: TextStyle(color: cs.onSurface)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          cursorColor: cs.primary,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter mobile number',
                            hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
            child: auth.isLoading
              ? CircularProgressIndicator(color: cs.onPrimary)
              : const Text('Continue'),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: emailController,
                    cursorColor: cs.primary,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: cs.onSurface)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    cursorColor: cs.primary,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: cs.onSurface)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => _signInWithEmailViaAuth(
                                context,
                                emailController.text,
                                passwordController.text,
                              ),
                      style: ElevatedButton.styleFrom(foregroundColor: cs.onPrimary, backgroundColor: cs.primary),
                      child: auth.isLoading
                          ? CircularProgressIndicator(color: cs.onPrimary)
                          : const Text('Login'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to signup page
                        Navigator.of(context).pushNamed('/signup');
                        // If you use GetX routes: Get.toNamed('/signup');
                      },
                      child: const Text("Don't have an account? Sign up"),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Start a guest session and navigate to Home, removing
                        // previous routes so back cannot return to login.
                        await SessionService.setGuest(true);
                        if (!mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                      },
                      child: const Text('Continue as guest'),
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
