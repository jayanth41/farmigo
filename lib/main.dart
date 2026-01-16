import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/bookings_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
    try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  // Initialize Controllers
  Get.put<FavoritesController>(FavoritesController());
  Get.put<BookingsController>(BookingsController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farmigo',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const AuthStateHandler(),
      getPages: [
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
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

    // TODO: Uncomment when Firebase Auth is working
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   Get.offAllNamed('/home');
    // } else {
    //   Get.offAllNamed('/login');
    // }

    // For now, always go to login
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}