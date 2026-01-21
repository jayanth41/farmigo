import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../navigation/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // USER PROFILE SECTION (NEW - with green gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D5016), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSBfQxPUpNyNBYwV5GaPRHuWl99CoppaBrO4Q&s',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jayanth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'jayanthmasampalli@gmail.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // NAVIGATION ITEMS
          _buildDrawerItem(
            context,
            icon: Icons.home,
            label: 'Home',
            onTap: () => _navigateTo(context, AppRoutes.home),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.favorite,
            label: 'Favorites',
            onTap: () => _navigateTo(context, AppRoutes.favorites),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today,
            label: 'Bookings',
            onTap: () => _navigateTo(context, AppRoutes.bookings),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            label: 'Profile',
            onTap: () => _navigateTo(context, AppRoutes.profile),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D5016)),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context);
    try {
      Get.toNamed(route);
    } catch (_) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  void _logout(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Add Firebase logout
              // FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}