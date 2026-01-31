import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../screens/about_us_screen.dart';
import '../screens/terms_policy_screen.dart';
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
    final navigator = Navigator.of(context);

    // Schedule navigation after the drawer closes to avoid context misuse.
    Future.microtask(() {
      try {
        // If route is home, try to return to the first route. If the first
        // route is not the home route, push home. This avoids using
        // pushReplacement directly for Home.
        if (route == AppRoutes.home) {
          try {
            // Prefer Get to ensure named route mapping is used consistently.
            Get.offAllNamed(AppRoutes.home);
          } catch (e) {
            debugPrint('Error navigating to Home via Get: $e');
            try {
              navigator.popUntil((r) => r.isFirst);
              final current = ModalRoute.of(navigator.context)?.settings.name;
              if (current != route) {
                navigator.pushNamed(route);
              }
            } catch (e2) {
              debugPrint('Fallback home navigation error: $e2');
            }
          }
        } else {
          navigator.pushNamed(route);
        }
      } catch (e) {
        debugPrint('Drawer navigation error: $e');
      }
    });
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
            onPressed: () async {
              Navigator.pop(ctx);
              // Clear guest flag and Supabase session, then navigate to login and
              // remove all previous routes so back cannot return to the app.
              try {
                await SessionService.clear();
              } catch (_) {}
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}

              if (!context.mounted) return;
              final navigator = Navigator.of(context);
              Future.microtask(() {
                try {
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                } catch (e) {
                  debugPrint('Logout navigation error: $e');
                }
              });
            },
            child: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final muted = onSurface.withOpacity(0.6);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home, color: Theme.of(context).colorScheme.onPrimary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Farmigo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: surface,
                          child: Text(
                            (profile?['name'] ?? 'U')
                                    .toString()
                                    .isNotEmpty
                                ? (profile?['name']?[0] ?? 'U')
                                : 'U',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isProfileLoading
                              ? Text(
                                  'Loading...',
                                  style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9)),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?['name'] ?? "Guest User",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                    if (isOwner)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary,
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

            // ===== BODY =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle("Navigation", muted),
                  _item(context, Icons.home_outlined, "Home",
                      () => _navigateTo(context, AppRoutes.home)),
                  _item(context, Icons.favorite_border, "Favorites",
                      () => _navigateTo(context, AppRoutes.favorites)),
                  _item(context, Icons.calendar_month_outlined, "My Bookings",
                      () => _navigateTo(context, AppRoutes.bookings)),
                  _item(context, Icons.person_outline, "Profile",
                      () => _navigateTo(context, AppRoutes.profile)),

                  const SizedBox(height: 16),
                  _sectionTitle("More", muted),
                  _item(context, Icons.settings_outlined, "Settings",
                      () => _navigateTo(context, AppRoutes.settings)),
                  _item(context, Icons.card_giftcard, "Offers & Coupons",
                      () => _navigateTo(context, AppRoutes.offers)),
                  _item(context, Icons.help_outline, "Help & Support",
                      () => _navigateTo(context, AppRoutes.helpSupport)),
                  _item(context, Icons.info_outline, "About Us", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutUsScreen()),
                    );
                  }),
                  _item(context, Icons.privacy_tip_outlined,
                      "Terms & Privacy Policy", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TermsPolicyScreen()),
                    );
                  }),
                ],
              ),
            ),

            // ===== LOGOUT =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: colorScheme.error),
                ),
                onPressed: () => _logout(context),
                icon: Icon(Icons.logout_outlined, color: colorScheme.error),
                label: Text(
                  "Logout",
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ListTile(
      onTap: () {
        final navigator = Navigator.of(context);
        try {
          navigator.pop();
        } catch (e) {
          debugPrint('Error closing drawer: $e');
        }

        // If a parent provided a delegate and this label maps to a route in
        // AppRoutes, prefer delegating so parent can decide (eg. tab switch,
        // permission checks). For other labels (help/about) fall back to the
        // item's provided handler which does a MaterialPageRoute push.
        if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(label)) {
          // call delegate after drawer closes
          Future.microtask(() => onItemSelected!(label));
          return;
        }

        // fallback to the provided tap handler when no delegate is present
        Future.microtask(() {
          try {
            onTap();
          } catch (e) {
            debugPrint('Drawer item tap error: $e');
          }
        });
      },
      leading: Icon(icon, color: onSurface),
      title: Text(
        label,
        style: TextStyle(color: onSurface),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
