import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/snackbar_helper.dart';
import 'otp_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _identifierController = TextEditingController();

  void _showSnack(String msg, {bool error = true}) {
    showAppSnack(context, msg, isError: error);
  }

  void _sendOtp() {
    final value = _identifierController.text.trim();
    if (value.isEmpty) {
      _showSnack('Enter email or phone');
      return;
    }

    if (value.contains('@')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OTPScreen(value: value, authType: AuthType.email)),
      );
      return;
    }

    final digits = RegExp(r'^[0-9]+$');
    if (!digits.hasMatch(value) || value.length < 7) {
      _showSnack('Enter a valid phone number');
      return;
    }

    var phone = value;
    if (!phone.startsWith('+') && phone.length == 10) phone = '+91$phone';

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OTPScreen(value: phone, authType: AuthType.phone)),
    );
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
                Container(
                  height: 92,
                  width: 92,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add, size: 48, color: cs.primary),
                ),
                const SizedBox(height: 20),
                Text('Create Account', style: txt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Sign up to get started', style: txt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                const SizedBox(height: 24),

                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Email or Phone number',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Container(alignment: Alignment.center, child: Text('Send OTP', style: txt.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold))),
                  ),
                ),

                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Already have an account? '), TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Login'))]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
