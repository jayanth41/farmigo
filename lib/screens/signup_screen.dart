import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/user_service.dart';
import '../widgets/snackbar_helper.dart';
import '../navigation/app_routes.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> signUpUser(String email, String password, String confirmPassword, String name, String phone) async {
    final auth = Provider.of<AuthController>(context, listen: false);

    final trimmedEmail = email.trim();
    final trimmedPassword = password;
    final trimmedConfirm = confirmPassword;
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    // Client-side validation
    if (trimmedEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email')));
      return;
    }
    if (!trimmedEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid email')));
      return;
    }
    if (trimmedPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter password')));
      return;
    }
    if (trimmedPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be minimum 6 characters')));
      return;
    }
    if (trimmedPassword != trimmedConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Call controller
  final success = await auth.signUp(email: trimmedEmail, password: trimmedPassword, name: trimmedName, phone: trimmedPhone);

    if (!mounted) return;

    if (success) {
      showAppSnack(context, 'Signup successful', isSuccess: true);
      // Attempt automatic sign-in after signup
      try {
        final signedIn = await auth.signIn(email: trimmedEmail, password: trimmedPassword);
        if (!mounted) return;
        if (signedIn) {
          showAppSnack(context, 'Logged in', isSuccess: true);
          try {
            Get.offAllNamed(AppRoutes.home);
          } catch (_) {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
          }
          return;
        }
      } catch (_) {}

      // If automatic sign-in didn't happen (email verification flows), route to login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      final msg = auth.errorMessage ?? 'Signup failed';
      showAppSnack(context, msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
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
                  color: Colors.green,
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
                "Create your account",
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
                    _inputField(
                      controller: nameController,
                      hint: "Full Name",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: phoneController,
                      hint: "Phone Number",
                      icon: Icons.phone,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: confirmPasswordController,
                      hint: "Confirm Password",
                      icon: Icons.lock,
                      isPassword: true,
                    ),

                    const SizedBox(height: 24),

                    _primaryButton(
                      text: "Sign Up →",
                      loading: auth.isLoading,
                      onTap: () => signUpUser(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                        confirmPasswordController.text.trim(),
                        nameController.text.trim(),
                        phoneController.text.trim(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Get.offNamed('/login'),
                      child: const Text("Already have an account? Login"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPER WIDGETS ----------------

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
          backgroundColor: Colors.green,
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
}
