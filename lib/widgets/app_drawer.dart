import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../navigation/app_routes.dart';

/// AppDrawer with optional profile and callback support. Kept intentionally
/// simple so it works with the HomeScreen expectations.
class AppDrawer extends StatelessWidget {
  final String? activeItem;
  final ValueChanged<String>? onItemSelected;
  final Map<String, dynamic>? profile;
  final bool isProfileLoading;

  const AppDrawer({
    super.key,
    this.activeItem,
    this.onItemSelected,
    this.profile,
    this.isProfileLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Farmigo', style: TextStyle(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 8),
                if (isProfileLoading)
                  const SizedBox(height: 20, child: CircularProgressIndicator(color: Colors.white))
                else if (profile != null)
                  Text(profile!['name'] ?? 'Guest', style: const TextStyle(color: Colors.white70))
                else
                  const Text('Not signed in', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              onItemSelected?.call('Home');
              try {
                Get.offAllNamed(AppRoutes.home);
              } catch (_) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Bookings'),
            onTap: () {
              Navigator.pop(context);
              onItemSelected?.call('Bookings');
              try {
                Get.toNamed(AppRoutes.bookings);
              } catch (_) {
                Navigator.of(context).pushNamed(AppRoutes.bookings);
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              onItemSelected?.call('Favorites');
              try {
                Get.toNamed(AppRoutes.favorites);
              } catch (_) {
                Navigator.of(context).pushNamed(AppRoutes.favorites);
              }
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              onItemSelected?.call('Logout');
              try {
                Get.offAllNamed('/login');
              } catch (_) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
