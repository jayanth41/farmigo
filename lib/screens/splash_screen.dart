import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller for fade-in effect
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Navigate to Home after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  Color(0xFF2E7D32),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // CENTER CONTENT WITH FADE-IN
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo in a rounded white box
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.08),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_f.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) {
                          return const Icon(Icons.park,
                              size: 60, color: AppColors.primary);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Brand Name
                  const Text(
                    'Farmigo',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Your Gateway to Perfect Getaways',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),

                  const SizedBox(height: 30),

                  // Features Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _smallFeature(Icons.home, 'Farmhouses'),
                      const SizedBox(width: 20),
                      _smallFeature(Icons.hotel, 'Hotels'),
                      const SizedBox(width: 20),
                      _smallFeature(Icons.flight, 'Flights'),
                      const SizedBox(width: 20),
                      _smallFeature(Icons.directions_car, 'Cars'),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Animated Progress Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60.0),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          color: Colors.white,
                          backgroundColor:
                              const Color.fromRGBO(255, 255, 255, 0.12),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Preparing your experience...',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
