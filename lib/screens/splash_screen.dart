import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'login_screen.dart';
import 'home_screen.dart';
// Note: keep imports minimal for the splash's one-shot auth check.
// splash uses named navigation; don't import HomeScreen directly to avoid
// accidental direct widget pushes.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Slight zoom-in animation (starts a bit smaller and overshoots slightly)
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Start animation
    _controller.forward();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    fb.User? user;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('[Splash] Firebase init failed: $e');
    }

    try {
      user = fb.FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('[Splash] FirebaseAuth access failed: $e');
      user = null;
    }

    // Ensure splash delay AFTER everything is ready
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 41, 70, 92),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color.fromARGB(255, 41, 70, 92),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'SKY',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const TextSpan(
                          text: 'BASE',
                          style: TextStyle(
                            color: Color(0xFFB9C5CC),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Stay Above Expectations.',
                style: TextStyle(
                  color: Color(0xFFB9C5CC),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}