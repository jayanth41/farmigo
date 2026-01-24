import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
 


/// A modern travel-app style Drawer for the Farmigo app.
///
/// This widget is UI-only: it accepts an [activeItem] label to
/// highlight the current menu entry but does not perform navigation.
class AppDrawer extends StatelessWidget {
  final String? activeItem;
  final ValueChanged<String>? onItemSelected;
  final Map<String, dynamic>? profile;
  final bool isProfileLoading;

  const AppDrawer({super.key, this.activeItem, this.onItemSelected, this.profile, this.isProfileLoading = false});

  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 12.0;
  // avatar size constant removed — CircleAvatar used directly in the profile card

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
                  ),
                ),
                child: Row(
                  children: [
                    // white rounded square with logo icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.agriculture, color: AppColors.primary, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Farmigo',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Circular close button
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: AppColors.primary),
                      ),
                    ),
                  ],
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

                    const SizedBox(height: 16),
                    _SectionTitle('Other'),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(icon: Icons.local_offer, label: 'Offers & Deals', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.notifications_none, label: 'Notifications', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.settings, label: 'Settings', mutedBackground: true, onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.help_outline, label: 'Help & Support', onSelected: onItemSelected),
                    _DrawerMenuItem(icon: Icons.shield, label: 'Privacy Policy', onSelected: onItemSelected),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool mutedBackground;
  final ValueChanged<String>? onSelected;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.mutedBackground = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
  final bg = active
    ? AppColors.chipBg
    : (mutedBackground ? const Color.fromRGBO(229, 231, 235, 0.6) : Colors.transparent);
    final iconColor = active ? AppColors.primary : AppColors.iconGrey;
    final textColor = active ? AppColors.primary : AppColors.textMain;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        onTap: () {
          Navigator.of(context).pop();
          if (onSelected != null) onSelected!.call(label);
        },
      ),
    );
  }
}
