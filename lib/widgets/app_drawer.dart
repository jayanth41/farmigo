import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../navigation/app_routes.dart';

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

  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 12.0;

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
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
              // HEADER WITH GRADIENT
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: _verticalPadding,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D5016), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        (profile?['name'] ?? 'U')
                                .toString()
                                .isNotEmpty
                            ? (profile?['name']?.toString()[0] ?? 'U')
                            : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isProfileLoading)
                      const Text(
                        'Loading profile...',
                        style: TextStyle(color: Colors.white70),
                      )
                    else if (profile == null)
                      const Text(
                        'Welcome Guest',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile!['name'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile!['phone'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // NAVIGATION ITEMS
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _horizontalPadding,
                    vertical: 8,
                  ),
                  children: [
                    _SectionTitle('Main'),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      label: 'Home',
                      onTap: () => _navigateTo(context, AppRoutes.home),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.favorite_border,
                      label: 'My Favorites',
                      onTap: () => _navigateTo(context, AppRoutes.favorites),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.calendar_today,
                      label: 'My Bookings',
                      onTap: () => _navigateTo(context, AppRoutes.bookings),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.person_outline,
                      label: 'Profile',
                      onTap: () => _navigateTo(context, AppRoutes.profile),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('Categories'),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      context,
                      icon: Icons.agriculture,
                      label: 'Farmhouses',
                      onTap: () =>
                          _navigateTo(context, AppRoutes.farmhouses),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.villa,
                      label: 'Villas',
                      onTap: () => _navigateTo(context, '/villas'),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.hotel,
                      label: 'Hotels',
                      onTap: () => _navigateTo(context, '/hotels'),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.flight,
                      label: 'Flights',
                      onTap: () => _navigateTo(context, '/flights'),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.directions_car,
                      label: 'Car Rentals',
                      onTap: () => _navigateTo(context, AppRoutes.carRentals),
                    ),
                  ],
                ),
              ),

              // LOGOUT BUTTON
              Padding(
                padding: const EdgeInsets.all(_horizontalPadding),
                child: _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: () => _logout(context),
                  isLogout: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF2D5016),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}