import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:provider/provider.dart';

import 'filters/filters_provider.dart';
import 'navigation/app_routes.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/car_rentals_screen.dart';
import 'screens/farmhouses_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/offers_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/booking_history_screen.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/bookings_controller.dart';
import 'controllers/app_location_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'settings/theme_provider.dart';
import 'services/firebase_helper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App uses Firebase for authentication and Firestore for user profiles.
  // Any external database-backed services should be migrated separately.

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // mark firebase available for guarded services
      FirebaseHelper.setAvailable(true);
    } catch (e, st) {
      debugPrint('⚠️ Firebase.initializeApp failed: $e');
      debugPrint('$st');
      FirebaseHelper.setAvailable(false);
    }
  
  }

  Get.put(FavoritesController());
  Get.put(BookingsController());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsController()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => FiltersProvider()),
        ChangeNotifierProvider(create: (_) => AppLocationController()..initialize()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farmigo',

      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.themeMode,

      // Use a one-time splash check instead of switching the app root on
      // every authStateChanges event. This prevents auth state events from
      // unexpectedly replacing the entire app (and re-triggering login)
      // while preserving FirebaseAuth as the canonical auth source.
      home: const SplashScreen(),

      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupPage()),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(name: AppRoutes.favorites, page: () => const FavoritesScreen()),
        GetPage(name: AppRoutes.bookings, page: () => const BookingsScreen()),
        GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
  GetPage(name: AppRoutes.bookingHistory, page: () => const BookingHistoryScreen()),
  // Location selector is used as a modal bottom sheet (LocationSelectorScreen)
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
        GetPage(name: AppRoutes.offers, page: () => const OffersScreen()),
        GetPage(name: AppRoutes.helpSupport, page: () => const HelpSupportScreen()),
        GetPage(name: AppRoutes.farmhouses, page: () => const FarmhousesScreen()),
        GetPage(name: AppRoutes.carRentals, page: () => const CarRentalsScreen()),
      ],
    );
  }
}

// Call this from your logout drawer item's onTap
void _showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              // Close only the dialog
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close the dialog immediately
              Navigator.of(dialogContext).pop();

              // Try to also close the drawer if it's still open.
              // The `context` passed into _showLogoutConfirmation should be the
              // drawer's context (e.g. the one from the drawer widget),
              // so popping once will close the drawer if it is open.
              try {
                Navigator.of(context).pop();
              } catch (_) {
                // ignore: no-op if there's nothing to pop
              }

              // Perform the logout / navigation
              await _performLogoutAndNavigate(context);
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );
}

Future<void> _performLogoutAndNavigate(BuildContext context) async {
  try {
    // Use FirebaseAuth directly so authStateChanges stream updates the UI.
    await fb.FirebaseAuth.instance.signOut();
    // Optionally clear session data
    // After sign-out, navigate to Login and remove all previous routes so
    // back navigation won't return to authenticated screens.
    try {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint('Navigation to login after signOut failed: $e');
    }
  } catch (e, st) {
    // Log for debugging
    debugPrint('Logout failed: $e\n$st');

    // Show a short message to the user (only if widget tree still mounted)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
}
