import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart' show FirebaseMessaging, RemoteMessage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as env;

import 'filters/filters_provider.dart';
import 'navigation/app_routes.dart';
import 'theme/app_theme.dart';
import 'helpers/test_data_helper.dart';
import 'helpers/seed_farmhouse_data.dart';
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
import 'screens/owner_dashboard.dart';
import 'screens/car_owner_dashboard_new.dart';
import 'controllers/app_location_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'settings/theme_provider.dart';
import 'services/airport_service.dart';
import 'firebase_options.dart';
import 'screens/admin_chat_screen.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>();

// Top-level background message handler required by firebase_messaging.
// This must be a top-level function so the Android background isolate
// can execute it when the app is in the background.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  debugPrint('[FCM][background] message=${message.messageId} data=${message.data}');

  // If you want to update Firestore or schedule a local notification from
  // background, do it here. Keep this handler lightweight.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reduce unnecessary rebuild/jank on some devices (OnePlus fix)
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Global error: $error');
    return true;
  };

  // Load environment variables before anything uses them.
  // If this fails we WANT to see the error instead of silently continuing,
  // because services like DuffelService depend on these values.
  await env.dotenv.load(fileName: "assets/.env");
  debugPrint('[Main] .env successfully loaded');

  debugPrint("🚨🚨🚨 MAIN() STARTED — CHECKING APP CHECK 🚨🚨🚨");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Disable Firestore cache (fix OnePlus device issue)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  // Register background message handler for FCM. Handler must be a
  // top-level function (not a closure) so the Android background isolate
  // can invoke it.
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Main] Failed to register onBackgroundMessage: $e');
  }


  // Request notification permission from FirebaseMessaging
  await _requestNotificationPermission();

  // Load airport database for flight autocomplete
  try {
    await AirportService.loadAirports();
    debugPrint('[Main] Airport database loaded');
  } catch (e) {
    debugPrint('[Main] Failed to load airport database: $e');
  }

  // ❌ REMOVE App Check activation in debug
// We'll enable it properly later for release builds only


  runApp(const MyApp());
}

Future<void> _requestNotificationPermission() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  } catch (e) {
    debugPrint('Error requesting notification permission: $e');
  }
}

Future<void> saveFcmTokenToFirestore(String userId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('Failed to get FCM token');
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    debugPrint('FCM token saved for user $userId: $token');
  } catch (e) {
    debugPrint('Error saving FCM token: $e');
  }
}






class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Move Providers inside MyApp so `main()` can remain the exact minimal
    // Firebase initializer requested while preserving the app-wide providers.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsController()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => FiltersProvider()),
        ChangeNotifierProvider(create: (_) => AppLocationController()..initialize()),
      ],
      child: Builder(builder: (context) {
        final themeProvider = context.watch<ThemeProvider>();
        return GetMaterialApp(
          navigatorKey: rootNavKey,
          debugShowCheckedModeBanner: false,
          title: 'Skybase',
          theme: AppTheme.lightTheme().copyWith(
            textTheme: AppTheme.lightTheme().textTheme.apply(
              fontFamily: 'Poppins',
            ),
          ),
          darkTheme: AppTheme.darkTheme().copyWith(
            textTheme: AppTheme.darkTheme().textTheme.apply(
              fontFamily: 'Poppins',
            ),
          ),
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
            GetPage(name: '/home', page: () => const HomeScreen()),
            GetPage(name: AppRoutes.favorites, page: () => const FavoritesScreen()),
            GetPage(name: AppRoutes.bookings, page: () => const BookingsScreen()),
            GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
            // Location selector is used as a modal bottom sheet (LocationSelectorScreen)
            GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
            GetPage(name: AppRoutes.offers, page: () => const OffersScreen()),
            GetPage(name: AppRoutes.helpSupport, page: () => const HelpSupportScreen()),
            GetPage(name: AppRoutes.farmhouses, page: () => const FarmhousesScreen()),
            GetPage(name: AppRoutes.carRentals, page: () => const CarRentalsScreen()),
            GetPage(name: '/owner',page: () => const CarOwnerDashboard(),transition: Transition.rightToLeft,),
            GetPage(name:  '/adminChat',page: () => const AdminChatScreen(),),
            GetPage(name: '/owner-dashboard', page: () => const OwnerDashboard(), transition: Transition.rightToLeft),
          ],
        );
      }),
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
