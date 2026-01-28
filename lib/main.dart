import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'navigation/app_routes.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/car_rentals_screen.dart';
import 'screens/farmhouses_screen.dart';
import 'screens/signup_screen.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/bookings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://kvnwikjxjimztjqsycti.supabase.co',

      //anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2bndpa2p4amltenRqc3ljdGkiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTcxNzU4NzM4MywiZXhwIjoyMDMzMTYzMzgzfQ.1f-u3kSrcI4H3xB23J22G4on2a3M2R62K5c0ZaR-i-c',
      //anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2bndpa2p4amltenRqcXN5Y3RpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4ODgxMDcsImV4cCI6MjA4NDQ2NDEwN30.e-mZfYqzztQNbBQ4n0R3aKFFYhdGI6rZgKvgyJNx2Fw',

      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2bndpa2p4amltenRqcXN5Y3RpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4ODgxMDcsImV4cCI6MjA4NDQ2NDEwN30.e-mZfYqzztQNbBQ4n0R3aKFFYhdGI6rZgKvgyJNx2Fw',

    );
    debugPrint('✅ Supabase initialized');
  } catch (e) {
    debugPrint('❌ Supabase init error: $e');
  }

  // Initialize Firebase
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Register GetX controllers
  Get.put(FavoritesController());
  Get.put(BookingsController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farmigo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
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