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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EC), // light cream
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // LOGO - F Symbol
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7CB342),
                    const Color(0xFF4CAF50),
                    const Color.fromARGB(255, 12, 57, 14),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(76, 175, 80, 0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'F',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // APP NAME
            const Text(
              "FARMIGO",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 12),

            // TAGLINE
            const Text(
              "Find Your Perfect Escape",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF558B2F),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 50),

            // ICON ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(76, 175, 80, 0.1),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF4CAF50),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Book Unique\nFarmhouses",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF558B2F),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 50),

                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(76, 175, 80, 0.1),
                      ),
                      child: const Icon(
                        Icons.event_note,
                        color: Color(0xFF4CAF50),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Experience\nRural Charm",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF558B2F),
                      ),
                    ),
                  ],
                ),

              ],
            ),

            const SizedBox(height: 50),

            // LOADING INDICATOR
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
