import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
 

import '../navigation/app_routes.dart';

class AppDrawer extends StatelessWidget {
  final String? activeItem;
  final ValueChanged<String>? onItemSelected;
  final Map<String, dynamic>? profile;
  final bool isProfileLoading;

  const AppDrawer({super.key, this.activeItem, this.onItemSelected, this.profile, this.isProfileLoading = false});

  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 12.0;
  // avatar size constant removed — CircleAvatar used directly in the profile card
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top header (give an explicit height so decoration has bounded constraints)
              Container(
                height: 96,
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: _verticalPadding,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
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
              ),

              const SizedBox(height: 18),

              // User area: show a compact profile card (copied from Home header)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          child: Text((profile?['name'] ?? '').toString().isNotEmpty ? (profile?['name']?[0] ?? 'U') : 'U'),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isProfileLoading) ...[
                                const Text(
                                  'Loading profile...',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Please wait',
                                  style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
                                ),
                              ] else if (profile == null) ...[
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                // Show sign-in action when no profile exists
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    try {
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    } catch (_) {}
                                  },
                                  child: const Text('Sign in', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
                                ),
                              ] else ...[
                                Text(
                                  'Welcome back ${profile!['name'] ?? 'User'}',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile!['phone'] ?? '',
                                  style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onItemSelected != null) onItemSelected!('Profile');
                          },
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Menu sections
            Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                  children: [
                    _SectionTitle('Main'),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(
                      icon: Icons.home,
                      label: 'Home',
                      active: activeItem == 'Home',
                      onSelected: onItemSelected,
                    ),
                    _DrawerMenuItem(icon: Icons.favorite_border, label: 'My Favorites', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.calendar_today, label: 'My Bookings', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.person_outline, label: 'Profile', onSelected: onItemSelected),

                    const SizedBox(height: 16),
                    _SectionTitle('Categories'),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(icon: Icons.agriculture, label: 'Farmhouses', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.villa, label: 'Villas', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.hotel, label: 'Hotels', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.flight, label: 'Flights', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.directions_car, label: 'Car Rentals', onSelected: onItemSelected),
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