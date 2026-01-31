import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// theme colors are used from Theme.of(context).colorScheme
import '../controllers/auth_controller.dart';
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
  bool _isLoading = false;

  // ---------------- SEND OTP ----------------
  Future<void> _sendOTP() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      _showSnackBar('Enter valid 10-digit mobile number');
      return;
    }

    setState(() => _isLoading = true);

    final authCtrl = context.read<AuthController>();

    final success =
        await authCtrl.startPhoneNumberVerification('+91$phone');

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            phoneNumber: '+91$phone',
          ),
        ),
      );
    } else {
      _showSnackBar(authCtrl.errorMessage ?? 'Failed to send OTP');
    }
  }

  // EMAIL LOGIN
  Future<void> _signInWithEmailViaAuth(
      BuildContext context, String email, String password) async {
    final authCtrl = context.read<AuthController>();
    final success = await authCtrl.signIn(email: email, password: password);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Login successful')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${authCtrl.errorMessage}')),
      );
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
                      onPressed: _isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
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
                  Consumer<AuthController>(
                    builder: (context, authCtrl, _) {
                        return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authCtrl.isLoading
                              ? null
                              : () => _signInWithEmailViaAuth(
                                    context,
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                  ),
                          style: ElevatedButton.styleFrom(foregroundColor: cs.onPrimary, backgroundColor: cs.primary),
                          child: authCtrl.isLoading
                              ? CircularProgressIndicator(color: cs.onPrimary)
                              : const Text('Login'),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      // Start a guest session and navigate to Home, removing
                      // previous routes so back cannot return to login.
                      await SessionService.setGuest(true);
                      if (!mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                    },
                    child: const Text('Continue as guest'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
