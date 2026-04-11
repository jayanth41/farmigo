import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/snackbar_helper.dart';
import '../screens/about_us_screen.dart';
import '../screens/terms_policy_screen.dart';
import '../screens/owner_onboarding_screen.dart';
import '../screens/owner_dashboard.dart';
import '../screens/add_property_screen.dart';
import '../screens/filters_screen.dart';
import '../models/category.dart';
import '../navigation/app_routes.dart';

/// Check owner verification status and route accordingly.
/// Returns true if owner verification indicates onboarding was already completed.
Future<bool> checkOwnerVerificationStatus({
  required BuildContext context,
  bool replace = false,
}) async {
  final uid = fb.FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showAppSnack(context, 'Sign in to access owner dashboard', isError: true);
      }
    });
    return false;
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('owner_verification')
        .doc(uid)
        .get();

    final verified =
        doc.exists && (doc.data()?['isOwnerDetailsSubmitted'] == true);

    // 🔹 Close drawer on ROOT navigator only (prevents losing context)
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {}

  // Very short wait so animations finish (reduced perfs delay)
  await Future.delayed(const Duration(milliseconds: 60));

    if (!context.mounted) return false;

    if (verified) {
      // If owner details submitted, check if they already have a property.
      final propQuery = await FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      final hasProperty = propQuery.docs.isNotEmpty;

      if (hasProperty) {
        if (replace) {
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(builder: (_) => const OwnerDashboard()),
          );
        } else {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const OwnerDashboard()),
          );
        }
      } else {
        if (replace) {
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
        } else {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
        }
      }
    } else {
      if (replace) {
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen()),
        );
      } else {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen()),
        );
      }
    }

    return verified;
  } catch (e) {
    debugPrint('Failed to check owner verification: $e');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showAppSnack(
          context,
          'Could not verify owner status — try again later',
          isError: true,
        );
      }
    });

    return false;
  }
}


/// App drawer used across the app.
///
/// Requirements implemented:
/// - Home, Favorites, Bookings navigate to their screens using Get.offAll()
///   so the Login screen is removed from the back stack.
/// - "Profile" item removed from the navigation list.
/// - Drawer header is clickable and navigates to `ProfileScreen`.
class AppDrawer extends StatefulWidget {
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
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Cache futures per-uid so multiple builders reuse the same Firestore read.
  static final Map<String, Future<Map<String, dynamic>?>> _userDocFutureCache = {};

  // Local last-seen copy to avoid flicker while future is loading again.
  Map<String, dynamic>? _lastSeenUserData;

  Future<Map<String, dynamic>?> _getUserDocFuture(String? uid) {
    if (uid == null || uid.isEmpty) return Future.value(null);
    if (_userDocFutureCache.containsKey(uid)) return _userDocFutureCache[uid]!;

    final fut = _fetchUserDoc(uid).then((data) {
      // store a local copy to render immediately on subsequent builds
      if (data != null) _lastSeenUserData = Map<String, dynamic>.from(data);
      return data;
    });

    _userDocFutureCache[uid] = fut;
    return fut;
  }

  // Owner role checks removed - app no longer exposes owner onboarding

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
              // Close the confirmation dialog first
              Navigator.of(ctx).pop();

              // Close the drawer if it's open (best-effort)
              try {
                Navigator.of(context).pop();
              } catch (_) {}

              final uid = fb.FirebaseAuth.instance.currentUser?.uid;

              // Sign out from Firebase
              try {
                await fb.FirebaseAuth.instance.signOut();
                // Clear any cached user futures for this uid to avoid stale data
                if (uid != null && uid.isNotEmpty) {
                  _userDocFutureCache.remove(uid);
                }
                _lastSeenUserData = null;
              } catch (e) {
                debugPrint('Logout failed: $e');
              }

              // Navigate to Login and clear the navigation stack so the user
              // can't navigate back into authenticated screens.
              try {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              } catch (e) {
                debugPrint('Navigation to login after logout failed: $e');
              }

              try {
                showAppSnack(context, 'Logged out successfully', isSuccess: true);
              } catch (_) {}
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
                // Always close the drawer, then navigate directly to Profile.
                // Remove delegation to parent via `onItemSelected` and label-based routing.
                try {
                  Navigator.of(context).pop();
                } catch (_) {}

                try {
                  Navigator.pushNamed(context, AppRoutes.profile);
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/skybase_logo.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'SKY',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onPrimary,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                TextSpan(
                                  text: 'BASE',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Small filter icon in header for quick access
                        IconButton(
                          icon: Icon(Icons.filter_alt, color: theme.colorScheme.onPrimary),
                          onPressed: () {
                            // Close drawer then open filters
                            try {
                              Navigator.of(context).pop();
                            } catch (_) {}
                            final cat = Category.all;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FiltersScreen(category: cat, initialFilters: {}, onFiltersApplied: (_) {})),
                            );
                          },
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
                            final uid = user?.uid;

                            if (uid == null) {
                              return CircleAvatar(
                                radius: 28,
                                backgroundColor: surface,
                                child: Text('U', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                              );
                            }

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _getUserDocFuture(uid),
                              builder: (context, snap) {
                                final fb.User? userLocal = fb.FirebaseAuth.instance.currentUser;

                                // If we have a last-seen copy use it to avoid flicker while loading
                                final fallback = _lastSeenUserData;

                                if (snap.connectionState == ConnectionState.waiting && fallback == null) {
                                  return CircleAvatar(
                                    radius: 28,
                                    backgroundColor: surface,
                                    child: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                }

                                final data = snap.data ?? fallback ?? {};
                                final displayName = (widget.profile?['name'] ?? data['name'] ?? userLocal?.displayName ?? '')?.toString() ?? '';
                                final email = (userLocal?.email ?? data['email'])?.toString();
                                final photoUrl = (data['photoUrl'] as String?) ?? userLocal?.photoURL;
                                final avatarLetter = displayName.isNotEmpty ? displayName[0] : (email?.isNotEmpty == true ? email![0] : 'U');

                                if (photoUrl != null && photoUrl.isNotEmpty) {
                                  return CircleAvatar(
                                    radius: 28,
                                    backgroundColor: surface,
                                    backgroundImage: NetworkImage(photoUrl),
                                  );
                                }

                                return CircleAvatar(
                                  radius: 28,
                                  backgroundColor: surface,
                                  child: Text(
                                    avatarLetter,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                          const SizedBox(width: 12),
                                      Expanded(
                            child: widget.isProfileLoading
                                ? Text(
                                    'Loading...',
                                    style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.9)),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: _getUserDocFuture(fb.FirebaseAuth.instance.currentUser?.uid ?? ''),
                                        builder: (context, snap) {
                                          final fb.User? user = fb.FirebaseAuth.instance.currentUser;
                                          final fallback = _lastSeenUserData;

                                          if (user == null) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Guest',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Please login to continue',
                                                  style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.9), fontSize: 12),
                                                ),
                                              ],
                                            );
                                          }

                                          if (snap.connectionState == ConnectionState.waiting && fallback == null) {
                                            return Row(
                                              children: [
                                                const SizedBox(width: 6),
                                                const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                                const SizedBox(width: 8),
                                                Text('Loading...', style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.9))),
                                              ],
                                            );
                                          }

                                          final data = snap.data ?? fallback ?? {};
                                          final displayName = (widget.profile?['name'] ?? data['name'] ?? user.displayName ?? '')?.toString() ?? '';
                                          final email = (user.email ?? data['email'])?.toString();

                                          // If doc missing, attempt to ensure it's created in background
                                          final uid = fb.FirebaseAuth.instance.currentUser?.uid;
                                          if (data.isEmpty && uid != null && uid.isNotEmpty) {
                                            ensureUserDoc(uid);
                                          }

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName.isNotEmpty ? displayName : 'Guest',
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
                                        },
                                      ),
                                      // Owner badge removed
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
                  // ===== SWITCH ACCOUNT =====
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _getUserDocFuture(fb.FirebaseAuth.instance.currentUser?.uid ?? ''),
                    builder: (context, snap) {
                      String activeRole = 'user';
                      bool isOwner = false;

                      final data = snap.data ?? _lastSeenUserData ?? {};

                      if (data.isNotEmpty) {
                        activeRole = (data['activeRole'] ?? 'user').toString();

                        final role = (data['role'] ?? 'user').toString();
                        final rolesRaw = data['roles'];
                        List<String> roles = [];
                        if (rolesRaw is List) {
                          roles = List<String>.from(rolesRaw);
                        } else if (rolesRaw is String) {
                          roles = [rolesRaw];
                        }

                        // Show switch only if user has owner capability
                        isOwner = role == 'owner' || roles.contains('farmhouse_owner') || roles.contains('car_owner');
                      }

                      // If user is not owner, don't render this section
                      if (!isOwner) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, color: colorScheme.onPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Switch Account",
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    activeRole == 'owner'
                                        ? "Owner Mode"
                                        : "User Mode",
                                    style: TextStyle(
                                      color: colorScheme.onPrimary.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: activeRole == 'owner',
                              activeThumbColor: colorScheme.onPrimary,
                              onChanged: (val) async {
                                final uid = fb.FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) return;

                                final newRole = val ? 'owner' : 'user';

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({'activeRole': newRole});

                                if (context.mounted) {
                                  showAppSnack(
                                    context,
                                    newRole == 'owner'
                                        ? 'Switched to Owner mode'
                                        : 'Switched to User mode',
                                    isSuccess: true,
                                  );

                                  // Reload app root so ModeRouter decides which UI to show
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/',
                                    (route) => false,
                                  );
                                }
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  _sectionTitle("Navigation", muted),
                  ListTile(
                    leading: Icon(Icons.home_outlined, color: onSurface),
                    title: Text('Home', style: TextStyle(color: onSurface)),
                    onTap: () {
                      // Close drawer first so the UI is tidy before navigation.
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}

                      // If parent scaffold wants to handle item selection (e.g.
                      // switch bottom tabs), delegate to it. This avoids
                      // creating a new Home route on top of the existing one.
                      if (widget.onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelHome)) {
                        Future.microtask(() => widget.onItemSelected!(AppRoutes.labelHome));
                        return;
                      }

                      // Attempt to reuse an existing Home route by popping until
                      // we find it. This avoids rebuilding Home if it's already
                      // present in the navigator stack. If Home isn't found we
                      // push it (normal push) so we don't clear the whole app.
                      try {
                        bool foundHome = false;

                        Navigator.of(context).popUntil((route) {
                          final name = route.settings.name;
                          if (name == (AppRoutes.labelToRoute[AppRoutes.labelHome] ?? AppRoutes.home)) {
                            foundHome = true;
                            return true; // stop popping; we've reached Home
                          }
                          // Stop at first route to avoid popping entire stack if Home
                          // is not present.
                          return route.isFirst;
                        });

                        // If we didn't find an existing Home route, push it so we
                        // land on Home without clearing unrelated routes.
                        if (!foundHome) {
                          final route = AppRoutes.labelToRoute[AppRoutes.labelHome] ?? AppRoutes.home;
                          Navigator.of(context).pushNamed(route);
                        }
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

                      if (widget.onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelFavorites)) {
                        Future.microtask(() => widget.onItemSelected!(AppRoutes.labelFavorites));
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

                      if (widget.onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelBookings)) {
                        Future.microtask(() => widget.onItemSelected!(AppRoutes.labelBookings));
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

                  FutureBuilder<Map<String, dynamic>?>(
                    future: _getUserDocFuture(fb.FirebaseAuth.instance.currentUser?.uid ?? ''),
                    builder: (context, snap) {
                      final data = snap.data ?? _lastSeenUserData ?? {};
                      bool isOwner = false;

                      if (data.isNotEmpty) {
                        final role = (data['role'] ?? '').toString();
                        final rolesRaw = data['roles'];
                        List<String> roles = [];
                        if (rolesRaw is List) {
                          roles = List<String>.from(rolesRaw);
                        } else if (rolesRaw is String) {
                          roles = [rolesRaw];
                        }

                        isOwner = role == 'owner' || roles.contains('farmhouse_owner') || roles.contains('car_owner');
                      }

                      if (isOwner) {
                        return ListTile(
                          leading: Icon(Icons.dashboard_outlined, color: onSurface),
                          title: Text('Owner Dashboard', style: TextStyle(color: onSurface)),
                          onTap: () {
                            try {
                              Navigator.of(context).pop();
                            } catch (_) {}

                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(builder: (_) => const OwnerDashboard()),
                            );
                          },
                        );
                      }

                      return ListTile(
                        leading: Icon(Icons.person_add_alt_1_outlined, color: colorScheme.primary),
                        title: Text('Become an Owner', style: TextStyle(color: onSurface)),
                        subtitle: const Text('Start earning from your property'),
                        onTap: () async {
                          // Use the centralized owner routing logic
                          await checkOwnerVerificationStatus(context: context);
                        },
                      );
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
                      if (widget.onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelSettings)) {
                        Future.microtask(() => widget.onItemSelected!(AppRoutes.labelSettings));
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
                      if (widget.onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelOffers)) {
                        Future.microtask(() => widget.onItemSelected!(AppRoutes.labelOffers));
                        return;
                      }
                      Navigator.pushNamed(context, '/offers');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: colorScheme.primary),
                    title: Text('Help & Support', style: TextStyle(color: onSurface)),
                    onTap: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (_) {}
                      if (widget.onItemSelected != null && AppRoutes.labelToRoute.containsKey(AppRoutes.labelHelp)) {
                        Future.microtask(() => widget.onItemSelected!(AppRoutes.labelHelp));
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

  /// Fetches the Firestore user document for the given uid. Returns null if
  /// not available or on error. Kept as an instance method so it can be used
  /// inside FutureBuilders in the header without introducing state.
  Future<Map<String, dynamic>?> _fetchUserDoc(String? uid) async {
    if (uid == null || uid.isEmpty) return null;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Use serverAndCache so we prefer fresh data but still benefit from
    // cached reads to reduce network calls and UI flicker.
    final snap = await docRef
      .get(const GetOptions(source: Source.serverAndCache))
      .timeout(const Duration(seconds: 5));

      if (!snap.exists) return null;

      final data = snap.data();

      if (data == null) return null;

      // 🔥 AUTO-FIX BAD DATA (roles as String → List)
      if (data['roles'] is String) {
        final fixedRoles = [data['roles']];
        await docRef.update({'roles': fixedRoles});
        data['roles'] = fixedRoles; // update locally also
      }

      return data;
    } catch (e) {
      debugPrint('Failed to fetch user doc for $uid: $e');
      return null;
    }
  }

  /// Ensure the user document exists. If missing, create a minimal doc with
  /// public fields. This is a safe, best-effort helper and will swallow
  /// permission errors (so it won't crash the UI in restricted environments).
  Future<void> ensureUserDoc(String uid) async {
    if (uid.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await docRef.get().timeout(const Duration(seconds: 5));
      if (snap.exists) return;

      final user = fb.FirebaseAuth.instance.currentUser;
     final data = {
  'name': user?.displayName ?? '',
  'email': user?.email ?? '',
  'phone': user?.phoneNumber ?? '',
  'photoUrl': user?.photoURL ?? '',
  'role': 'user', // DEFAULT ROLE
  'createdAt': FieldValue.serverTimestamp(),
};


      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      // Don't fail the UI; log for diagnostics
      debugPrint('ensureUserDoc failed for $uid: $e');
    }
  }
}
