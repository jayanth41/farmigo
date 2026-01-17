import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              'Farmigo',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Get.offAllNamed('/home');
            },
          ),

          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Bookings'),
            onTap: () {
              Get.toNamed('/bookings');
            },
          ),

          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            onTap: () {
              Get.toNamed('/favorites');
            },
          ),

          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Support'),
            onTap: () {
              // Close drawer first
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Support'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Email: support@farmigo.app'),
                      SizedBox(height: 8),
                      Text('Phone: +1 (800) 555-0123'),
                      SizedBox(height: 8),
                      Text('We typically respond within 24 hours.'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Later: FirebaseAuth.instance.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
