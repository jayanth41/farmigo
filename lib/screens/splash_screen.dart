import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Slight zoom-in animation (starts a bit smaller and overshoots slightly)
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Start animation
    _controller.forward();
    _goNext();
  }

  /// One-time navigation decision after the splash.
  /// RULE: Always go to HOME after splash.
  /// All owner/role decisions now happen ONLY when the user taps "Owner Dashboard".
  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final fb.User? user = fb.FirebaseAuth.instance.currentUser;

    try {
      if (user == null) {
        // Not signed in -> go to Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      // Signed in -> ALWAYS go to Home first (correct behavior)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      debugPrint('[SplashScreen] Navigation error: $e');
      if (mounted) {
        // Safe fallback: still go to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
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
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'SKY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                          ),
                        ),
                        TextSpan(
                          text: 'BASE',
                          style: TextStyle(
                            color: Color(0xFFD6D6D6),
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Stay Above Expectations.',
                  style: TextStyle(color: Color(0xFFB9C5CC), fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
