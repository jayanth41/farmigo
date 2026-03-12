import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users_screen.dart';
import 'screens/owners_screen.dart';
import 'screens/admin_chat_list_screen.dart';
import 'screens/property_approvals_screen.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
     options: const FirebaseOptions(
        apiKey: "AIzaSyAaNXzlIaKWzvR7w9688Zjnawm7fvr4_h0",
        authDomain: "farmigo-704ca.firebaseapp.com",
        projectId: "farmigo-704ca",
        storageBucket: "farmigo-704ca.appspot.com",
        messagingSenderId: "520560089620",
        appId: "1:520560089620:web:6b99e2e96fd93f916aa501",
      ),
    );
    debugPrint('[AdminApp] Firebase initialized successfully');
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('[AdminApp] Signed in anonymously');
    } else {
      debugPrint('[AdminApp] Admin already signed in');
    }
  } catch (e, st) {
    debugPrint('[AdminApp] Firebase initialization FAILED: $e');
    debugPrint('$st');
  }
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AdminHome(),
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int selectedIndex = 0;

  final screens = [
    const DashboardScreen(),
    const UsersScreen(),
    const OwnersScreen(),
    const AdminChatListScreen(),
    const PropertyApprovalsScreen(),
    const Center(child: Text("Bookings Screen")),
    const Center(child: Text("Payments Screen")),
    const Center(child: Text("Complaints Screen")),
    const Center(child: Text("Settings Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) {
              setState(() => selectedIndex = i);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard), label: Text("Dashboard")),
              NavigationRailDestination(
                  icon: Icon(Icons.people), label: Text("Users")),
              NavigationRailDestination(
                  icon: Icon(Icons.store), label: Text("Owners")),
        NavigationRailDestination(
          icon: Icon(Icons.chat), label: Text("Chats")),
              NavigationRailDestination(
                  icon: Icon(Icons.book), label: Text("Bookings")),
              NavigationRailDestination(
                  icon: Icon(Icons.payment), label: Text("Payments")),
              NavigationRailDestination(
                  icon: Icon(Icons.report), label: Text("Complaints")),
              NavigationRailDestination(
                  icon: Icon(Icons.settings), label: Text("Settings")),
            ],
          ),

          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Skybase Admin",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.account_circle, color: Colors.white),
                    ],
                  ),
                ),

                Expanded(
                  child: screens[selectedIndex],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}