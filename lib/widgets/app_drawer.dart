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

  bool get isOwner => profile?['is_owner'] == true;

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
      child: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.home, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Farmigo",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Text(
                            (profile?['name'] ?? 'U')
                                    .toString()
                                    .isNotEmpty
                                ? (profile?['name']?[0] ?? 'U')
                                : 'U',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isProfileLoading
                              ? const Text(
                                  "Loading...",
                                  style: TextStyle(color: Colors.white70),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?['name'] ?? "Guest User",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (isOwner)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "Property Owner",
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            // ===== BODY (SCROLLABLE) =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle("Navigation"),
          _item(Icons.home_outlined, "Home",
            () => _navigateTo(context, AppRoutes.home)),
          _item(Icons.favorite_border, "Favorites",
            () => _navigateTo(context, AppRoutes.favorites)),
          _item(Icons.calendar_month_outlined, "My Bookings",
            () => _navigateTo(context, AppRoutes.bookings)),
          _item(Icons.tune_outlined, "Filters",
            () => _navigateTo(context, '/filters')),
          _item(Icons.person_outline, "Profile",
            () => _navigateTo(context, AppRoutes.profile)),

                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    _sectionTitle("Owner Tools"),
          _item(Icons.dashboard_outlined, "Owner Dashboard",
            () => _navigateTo(context, '/owner-dashboard')),
          _item(Icons.add_outlined, "Add Property",
            () => _navigateTo(context, '/addProperty')),
                  ],

                  const SizedBox(height: 16),
                  _sectionTitle("More"),
          _item(Icons.settings_outlined, "Settings",
            () => _navigateTo(context, AppRoutes.settings)),
          _item(Icons.card_giftcard, "Offers & Coupons",
            () => _navigateTo(context, AppRoutes.offers)),
          _item(Icons.help_outline, "Help & Support",
            () => _navigateTo(context, '/help')),
          _item(Icons.info_outline, "About Us",
            () => _navigateTo(context, '/about')),
          _item(Icons.privacy_tip_outlined, "Terms & Privacy Policy",
            () => _navigateTo(context, '/terms')),
                ],
              ),
            ),

            // ===== LOGOUT FIXED BOTTOM =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_outlined, color: Colors.red),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: Icon(
            icon,
            color: AppColors.iconGrey,
            size: 22,
          ),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}