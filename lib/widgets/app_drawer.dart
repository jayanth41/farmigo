import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../widgets/snackbar_helper.dart';
import '../screens/about_us_screen.dart';
import '../screens/terms_policy_screen.dart';
// Navigation is performed via named routes (GetX) or delegated to parent
// `MainScaffold`. Avoid importing screen widgets directly to prevent unused
// import warnings when using named navigation.
import '../navigation/app_routes.dart';

/// App drawer used across the app.
///
/// Requirements implemented:
/// - Home, Favorites, Bookings navigate to their screens using Get.offAll()
///   so the Login screen is removed from the back stack.
/// - "Profile" item removed from the navigation list.
/// - Drawer header is clickable and navigates to `ProfileScreen`.
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

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await fb.FirebaseAuth.instance.signOut();
              } catch (e) {
                // Sign-out failed; proceed to let auth state handle routing
                debugPrint('Logout failed: $e');
              }

              try {
                Navigator.of(context).pop(); // close drawer if open
              } catch (_) {}

              try {
                showAppSnack(context, 'Logged out successfully', isSuccess: true);
              } catch (_) {}

              // Let app-level auth listener handle navigation to login
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
            InkWell(
              onTap: () {
                // Close drawer then navigate to Profile
                try {
                  Navigator.of(context).pop();
                } catch (_) {}

                if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelProfile)) {
                  Future.microtask(() => onItemSelected!(AppRoutes.labelProfile));
                  return;
                }

                try {
                  Navigator.of(context).pushNamed(AppRoutes.profile);
                } catch (e) {
                  debugPrint('Profile navigation error: $e');
                }
              },
              child: Container(
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
                        Icon(Icons.home, color: theme.colorScheme.onPrimary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Farmigo',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
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
                          Builder(builder: (ctx) {
                            final fb.User? user = fb.FirebaseAuth.instance.currentUser;
                            final String initials = (profile?['name'] ?? user?.displayName ?? user?.phoneNumber ?? 'U').toString();
                            final String avatarLetter = initials.isNotEmpty ? initials[0] : 'U';
                            final String? photoUrl = user?.photoURL;

                            return CircleAvatar(
                              radius: 28,
                              backgroundColor: surface,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? Text(
                                      avatarLetter,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : null,
                            );
                          }),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isProfileLoading
                                ? Text(
                                    'Loading...',
                                    style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.9)),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Builder(builder: (ctx) {
                                        final fb.User? user = fb.FirebaseAuth.instance.currentUser;
                                        final displayName = (profile?['name'] ?? user?.displayName ?? (user?.phoneNumber))?.toString() ?? 'Guest User';
                                        final email = user?.email;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            ),
                                            if (email != null && email.isNotEmpty)
                                              Text(email, style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.9), fontSize: 12)),
                                          ],
                                        );
                                      }),
                                      if (isOwner)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            "Property Owner",
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
            ),

            // ===== BODY =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle("Navigation", muted),
                  ListTile(
                    leading: Icon(Icons.home_outlined, color: onSurface),
                    title: Text('Home', style: TextStyle(color: onSurface)),
                    onTap: () {
                            // Close drawer first
                            try {
                              Navigator.of(context).pop();
                            } catch (_) {}

                            // Delegate to parent (MainScaffold) so it can switch tabs.
                            if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelHome)) {
                              Future.microtask(() => onItemSelected!(AppRoutes.labelHome));
                              return;
                            }

                            // Fallback: navigate to home and clear previous stack so Back
                            // doesn't return to login or previous screens. Use the
                            // Navigator API (not Get) to respect the app's top-level
                            // routing and auth-driven home logic.
                            try {
                              final route = AppRoutes.labelToRoute[AppRoutes.labelHome] ?? AppRoutes.home;
                              Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
                            } catch (e) {
                              debugPrint('Navigation to Home failed: $e');
                            }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.favorite_border, color: onSurface),
                    title: Text('Favorites', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}

                      if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelFavorites)) {
                        Future.microtask(() => onItemSelected!(AppRoutes.labelFavorites));
                        return;
                      }

                      try {
                        final route = AppRoutes.labelToRoute[AppRoutes.labelFavorites] ?? AppRoutes.favorites;
                        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
                      } catch (e) {
                        debugPrint('Navigation to Favorites failed: $e');
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_month_outlined, color: onSurface),
                    title: Text('My Bookings', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}

                      if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelBookings)) {
                        Future.microtask(() => onItemSelected!(AppRoutes.labelBookings));
                        return;
                      }

                      try {
                        final route = AppRoutes.labelToRoute[AppRoutes.labelBookings] ?? AppRoutes.bookings;
                        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
                      } catch (e) {
                        debugPrint('Navigation to Bookings failed: $e');
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle("More", muted),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: onSurface),
                    title: Text('Settings', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}
                      if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelSettings)) {
                        Future.microtask(() => onItemSelected!(AppRoutes.labelSettings));
                        return;
                      }
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.card_giftcard, color: onSurface),
                    title: Text('Offers & Coupons', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}
                      if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelOffers)) {
                        Future.microtask(() => onItemSelected!(AppRoutes.labelOffers));
                        return;
                      }
                      Navigator.pushNamed(context, '/offers');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: onSurface),
                    title: Text('Help & Support', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}
                      if (onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelHelp)) {
                        Future.microtask(() => onItemSelected!(AppRoutes.labelHelp));
                        return;
                      }
                      Navigator.pushNamed(context, '/help-support');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: onSurface),
                    title: Text('About Us', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: onSurface),
                    title: Text('Terms & Privacy Policy', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPolicyScreen()));
                    },
                  ),
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
