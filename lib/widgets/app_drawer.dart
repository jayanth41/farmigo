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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.park, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isProfileLoading
                        ? const SizedBox(height: 20, child: CircularProgressIndicator(color: Colors.white))
                        : Text(
                            profile != null ? (profile!['name'] ?? 'Guest') : 'Not signed in',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildTile(context, icon: Icons.home, label: 'Home', keyLabel: 'Home'),
                  _buildTile(context, icon: Icons.book, label: 'Bookings', keyLabel: 'Bookings', route: AppRoutes.bookings),
                  _buildTile(context, icon: Icons.favorite, label: 'Favorites', keyLabel: 'Favorites', route: AppRoutes.favorites),
                  const Divider(),
                  _buildTile(context, icon: Icons.manage_accounts, label: 'Owner Dashboard', keyLabel: 'Owner', route: '/owner'),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: _buildTile(context, icon: Icons.logout, label: 'Logout', keyLabel: 'Logout', route: '/login', replace: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, {required IconData icon, required String label, required String keyLabel, String? route, bool replace = false}) {
    final selected = activeItem != null && activeItem == keyLabel;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primaryDark : AppColors.iconGrey),
      title: Text(label),
      selected: selected,
      selectedTileColor: AppColors.chipBg,
      onTap: () {
        Navigator.pop(context);
        onItemSelected?.call(keyLabel);
        if (route != null) {
          try {
            if (replace) {
              Get.offAllNamed(route);
            } else {
              Get.toNamed(route);
            }
          } catch (_) {
            if (replace) {
              Navigator.of(context).pushReplacementNamed(route);
            } else {
              Navigator.of(context).pushNamed(route);
            }
          }
        }
      },
    );
  }
}
