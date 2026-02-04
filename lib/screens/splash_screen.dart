import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _goNext();
  }

  /// One-time navigation decision after the splash. If the user is already
  /// signed in, navigate to Home using pushAndRemoveUntil so that the
  /// app isn't replaced reactively by auth state changes; otherwise go to
  /// the login screen.
  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final fb.User? user = fb.FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Replace the splash with '/home' using pushReplacementNamed so the
      // splash screen is never on the back stack and navigation points to
      // the explicit '/home' route.
      try {
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        debugPrint('Splash -> Home navigation failed: $e');
      }
    } else {
      // Not signed in: go to login screen. Use pushReplacement so the
      // splash is removed from the stack.
      try {
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        debugPrint('Splash -> Login navigation failed: $e');
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 29, 163, 85),
              Color(0xFF2ECC71),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/images/farmigo_logo.png',
                    width: 150, height: 150,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Farmigo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Your Gateway to Perfect Getaways",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 24),

                // ICON ROW
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SplashIcon(icon: Icons.home, label: "Farmhouses"),
                    SizedBox(width: 20),
                    _SplashIcon(icon: Icons.hotel, label: "Hotels"),
                    SizedBox(width: 20),
                    _SplashIcon(icon: Icons.flight, label: "Flights"),
                    SizedBox(width: 20),
                    _SplashIcon(icon: Icons.directions_car, label: "Cars"),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Preparing your experience...",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 12),

                const SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                    minHeight: 4,
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

class _SplashIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SplashIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
