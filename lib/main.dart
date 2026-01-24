import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/bookings_controller.dart';
import 'navigation/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your screen widgets
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/car_rentals_screen.dart';
import 'screens/farmhouses_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'navigation/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (replace URL and anonKey with your project's values)
  try {
    await Supabase.initialize(
      url: 'https://kvnwikjxjimztjqsycti.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2bndpa2p4amltenRqcXN5Y3RpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4ODgxMDcsImV4cCI6MjA4NDQ2NDEwN30.e-mZfYqzztQNbBQ4n0R3aKFFYhdGI6rZgKvgyJNx2Fw',
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }
  
    // DEV: create a test user record if you want a quick verification write.
    // Replace or remove in production. This is wrapped in try/catch so it
    // doesn't crash the app if the table doesn't exist or the insert fails.
      // Insert a test user (dev-only). .select() returns the created row(s).
  
  // Initialize Controllers
  Get.put<FavoritesController>(FavoritesController());
  Get.put<BookingsController>(BookingsController());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farmigo',

      // ✅ START WITH SPLASH
      home: const SplashScreen(),

      getPages: [
        // Legacy tabbed HomeScreen remains at '/', keep for drawer/landing.
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
  // Support '/home' literal used across login/splash flows to show the
  // canonical HomeScreen used in the app.
  GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: AppRoutes.favorites, page: () => const FavoritesScreen()),
  GetPage(name: AppRoutes.farmhouses, page: () => const FarmhousesScreen()),
        GetPage(name: AppRoutes.carRentals, page: () => const CarRentalsScreen()),
        GetPage(name: AppRoutes.bookings, page: () => const BookingsScreen()),
        GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
  GetPage(name: '/signup', page: () => const SignupPage()),
        GetPage(name: '/splash', page: () => const SplashScreen()),
      ],
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // For development ensure the auth screens appear after Splash.
    // If you want automatic session-based routing, revert this to check
    // `Supabase.instance.client.auth.currentUser` and route accordingly.
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

void drawerCallback(BuildContext context, String label) {
  final route = AppRoutes.labelToRoute[label];
  if (route == null) return;

  // Prefer using Get navigation to ensure the route defined in getPages is used.
  // For main-tab routes your MainScaffold handles switching; for others we
  // navigate using Get so named routes from `getPages` resolve correctly.
  try {
    Get.toNamed(route);
  } catch (_) {
    // Fallback to Flutter navigator if Get fails for any reason.
    Navigator.of(context).pushReplacementNamed(route);
  }
}
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
      ],
    );
  }
}
