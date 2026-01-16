import 'dart:ui';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
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
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // CENTER CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo in a rounded white box (exact layout like provided image)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo_f.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) {
                        // if logo asset missing, show a green tree icon as fallback
                        return const Icon(Icons.park, size: 56, color: Color(0xFF1B5E20));
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // BRAND NAME
                const Text(
                  'Farmigo',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Your Gateway to Perfect Getaways',
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 28),

                // Icon row (Farmhouses, Hotels, Flights, Cars) — match image layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _smallFeature(Icons.home, 'Farmhouses'),
                    const SizedBox(width: 18),
                    _smallFeature(Icons.hotel, 'Hotels'),
                    const SizedBox(width: 18),
                    _smallFeature(Icons.flight, 'Flights'),
                    const SizedBox(width: 18),
                    _smallFeature(Icons.directions_car, 'Cars'),
                  ],
                ),

                const SizedBox(height: 28),

                // Thin progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60.0),
                  child: Column(
                    children: const [
                      SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          color: Colors.white,
                          backgroundColor: Color.fromRGBO(255, 255, 255, 0.12),
                          minHeight: 6,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Preparing your experience...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
