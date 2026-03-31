import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'owner_onboarding_screen.dart';
import 'owner_settings_screen.dart';
import 'home_screen.dart';
import 'car_owner_dashboard_new.dart';
import 'role_selection_screen.dart';
import 'owner/owner_main_scaffold.dart';
import 'owner_messages_screen.dart';
import 'owner_notifications_screen.dart';
import 'add_property_screen.dart' as add_screen;
import 'edit_property_screen.dart' as edit_screen;

/// OwnerDashboard now acts as a smart router:
/// It briefly shows a loader, checks Firestore, and then
/// automatically sends the user to the correct screen.
class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  bool _checking = true;
  bool _loadingProperties = true;
  String? _error;
  List<Map<String, dynamic>> _properties = [];
  String? _ownerCategory; // farmhouse | villa | hotel | hourly | car
  List<String>? _roles; // store user roles for conditional menu
  String? _ownerName; // owner's display name
  int _dashboardTabIndex = 0; // 0 = Active | 1 = Inactive | 2 = Pending
  String? _activeRole;

  int get _totalProperties => _properties.length;
  int get _activeProperties => _properties.where((p) {
    final status = (p['status'] ?? '').toString().toLowerCase();
    final approved = p['adminApproved'] == true;
    return approved && status == 'active';
  }).length;
  int get _totalBookings => _properties.fold<int>(0, (sum, p) => sum + ((p['totalBookings'] as num?)?.toInt() ?? 0));
  num get _totalEarnings =>
      _properties.fold<num>(0, (sum, p) => sum + ((p['revenue'] as num?) ?? 0));
  double get _avgRating {
    final ratings = _properties.map((p) => (p['rating'] as num?)?.toDouble()).whereType<double>().toList();
    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  @override
  void initState() {
    super.initState();

    // Pre-fill owner name from auth (so UI shows a name immediately while Firestore loads)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var initial = user.displayName;
        if (initial == null || initial.trim().isEmpty) {
          final email = user.email;
          if (email != null && email.isNotEmpty) {
            final local = email.split('@').first;
            final pretty = local.replaceAll(RegExp(r'[._]'), ' ');
            initial = pretty.split(' ').map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}').join(' ');
          }
        }
        if (initial != null && initial.isNotEmpty) {
          _ownerName = initial;
        }
      }
    } catch (_) {}

    // Run after first frame so navigation is safe
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeUser());
  }

  Future<void> _routeUser() async {
    debugPrint('[OwnerDashboard] _routeUser called');
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[OwnerDashboard] Current user: ${user?.uid}');
    // Defensive reset so we never stay stuck on loaders
    if (mounted) {
      setState(() {
        _checking = true;
        _loadingProperties = false;
        _error = null;
      });
    }
    
    if (user == null) {
      debugPrint('[OwnerDashboard] No user logged in, showing error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to access owner dashboard')),
      );
      // If there is no previous route to pop to (this screen may be the
      // app's initial route), avoid calling pop() which can leave the
      // Navigator in an invalid state. Instead, navigate to HomeScreen and
      // remove this route from the stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Get user roles and activeRole
        final userSnap = await firestore.collection('users').doc(uid).get();
        final data = userSnap.data();
        debugPrint('USER DOC DATA: ${userSnap.data()}');
        final roles = List<String>.from(data?['roles'] ?? []);
        final activeRole = data?['activeRole'] as String?;
        // Normalize older/ambiguous role values to the canonical role keys used
        // across the app. Some accounts use 'owner' while the code expects
        // 'farmhouse_owner' or 'car_owner'. Normalize here to avoid routing
        // fall-throughs.
        String? normalizedActiveRole = activeRole;
        if (activeRole != null) {
          final a = activeRole.toString().toLowerCase();
          if (a == 'owner' || a == 'farmhouse') normalizedActiveRole = 'farmhouse_owner';
          if (a == 'cowner' || a == 'coowner' || a == 'co_owner') normalizedActiveRole = 'car_owner';
        }
        _activeRole = normalizedActiveRole;

        var displayName = data?['displayName'] ?? data?['fullName'] ?? data?['name'] ?? data?['username'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Owner';

        // If Firestore/auth didn't provide a name, try deriving from email
        if ((displayName == null || (displayName is String && displayName.toString().trim().isEmpty) || displayName == 'Owner')) {
          final email = FirebaseAuth.instance.currentUser?.email;
          if (email != null && email.isNotEmpty) {
            final local = email.split('@').first;
            final pretty = local.replaceAll(RegExp(r'[._]'), ' ');
            final prettyCap = pretty.split(' ').map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}').join(' ');
            displayName = prettyCap;
          }
        }

        if (mounted) setState(() => _ownerName = displayName as String?);
        debugPrint('OWNER NAME FETCHED: $displayName (email:${FirebaseAuth.instance.currentUser?.email})');
        debugPrint('[OwnerDashboard] Owner name: $_ownerName');

      // NEW RULE: if activeRole is null AND the user has at least one owner role,
      // always ask them to select a role first.
      if (normalizedActiveRole == null && roles.isNotEmpty) {
        debugPrint('[OwnerDashboard] activeRole is null — forcing RoleSelectionScreen');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => RoleSelectionScreen(roles: roles)),
            );
          });
        }
        return;
      }

      // NEW USER CASE: logged in but not yet an owner
      final userRole = userSnap.data()?['role'] as String? ?? 'user';
      if (userRole == 'user' || roles.isEmpty) {
        debugPrint('[OwnerDashboard] New/normal user — redirecting to onboarding');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen()),
            );
          });
        }
        return;
      }

      if (mounted) setState(() => _roles = roles);
  debugPrint('[OwnerDashboard] User roles: $roles, activeRole: $activeRole (normalized: $normalizedActiveRole)');

      if (!mounted) return;

      // ROUTE BASED ON ROLES FIRST (not properties)
      
      // CASE-3: If user is ONLY car_owner (single role), go to CarOwnerDashboard
      if (roles.length == 1 && roles.contains('car_owner')) {
        debugPrint('[OwnerDashboard] CASE-3: Single car_owner role, redirecting to CarOwnerDashboard');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CarOwnerDashboard()),
          );
        });
        return;
      }

      // CASE-2: If user is ONLY farmhouse_owner, check for properties
      if (roles.length == 1 && roles.contains('farmhouse_owner')) {
        debugPrint('[OwnerDashboard] CASE-2: Single farmhouse_owner role');

        // Owner properties are stored in: Firestore → collection("properties")
        // Each document must contain: ownerId = current user's uid

    debugPrint('[OwnerDashboard] Checking properties in collection: properties where ownerId=$uid');

    // Use a robust helper that checks multiple possible owner fields to
    // handle documents that use different field names (ownerId, owner.uid,
    // owner). This avoids false negatives when older documents used a
    // different schema.
    final ownerDocs = await _queryPropertyDocsForOwner(uid);
    debugPrint('[OwnerDashboard] Properties found: ${ownerDocs.length}');
    final hasProperty = ownerDocs.isNotEmpty;
    debugPrint('[OwnerDashboard] farmhouse_owner has property: $hasProperty');

        if (!mounted) return;

        // Read onboarding/approval status from the user doc. Owner should
        // only be routed to AddPropertyScreen when onboarding is complete
        // AND admin has approved the account. If approval is pending, keep
        // the owner on the dashboard (they'll see any pending properties).
        final onboardingCompleted = userSnap.data()?['onboardingCompleted'] == true;
        final approvalStatus = (userSnap.data()?['approvalStatus'] ?? '').toString().toLowerCase();

        // If onboarding incomplete, send to onboarding screen
        if (!onboardingCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen()),
            );
          });
          return;
        }

        // If approval is not 'approved', keep user on dashboard (don't send to AddProperty)
        if (approvalStatus != 'approved') {
          setState(() => _checking = false);
          // Populate any properties we found (could be zero) so UI shows pending tab correctly
          await _populatePropertiesFromDocs(ownerDocs);
          return;
        }

        // At this point onboarding is complete and approval is 'approved'.
        // Show dashboard if any property exists.
        if (hasProperty) {
          setState(() => _checking = false);
          await _populatePropertiesFromDocs(ownerDocs);
          return;
        }

        // Only go to AddProperty if ZERO properties and account is approved
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const add_screen.AddPropertyScreen()),
          );
        });
        return;
      }

      // CASE-4: If user has MULTIPLE roles
      if (roles.length > 1) {
        // 4B: If activeRole is car_owner, go to CarOwnerDashboard
        if (normalizedActiveRole == 'car_owner') {
          debugPrint('[OwnerDashboard] CASE-4B: Multiple roles, activeRole=car_owner, redirecting to CarOwnerDashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CarOwnerDashboard()),
            );
          });
          return;
        }

        // 4C: If activeRole is farmhouse_owner, check for properties then load dashboard
        if (normalizedActiveRole == 'farmhouse_owner') {
          debugPrint('[OwnerDashboard] CASE-4C: Multiple roles, activeRole=farmhouse_owner');

          // Checking owner properties again for multi-role users
          debugPrint('[OwnerDashboard] (multi-role) checking properties where ownerId=$uid');

          final propsSnap = await firestore
              .collection('properties')
              .where('ownerId', isEqualTo: uid)
              .get();

          debugPrint('[OwnerDashboard] (multi-role) properties found: ${propsSnap.docs.length}');
          final hasProperty = propsSnap.docs.isNotEmpty;
          debugPrint('[OwnerDashboard] farmhouse_owner has property: $hasProperty');

          if (!mounted) return;

          // Always show dashboard if ANY property exists (even pending)
          if (hasProperty) {
            setState(() => _checking = false);
            await _loadProperties(uid);
            return;
          }

          // Only go to AddProperty if ZERO properties
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const add_screen.AddPropertyScreen()),
              );
          });
          return;
        }
      }

      // Fallback: if somehow we reach here, treat as verified owner with no properties
      debugPrint('[OwnerDashboard] Fallback reached — sending to AddPropertyScreen');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const add_screen.AddPropertyScreen()),
          );
        });
      }
      return;
    } catch (e) {
      debugPrint('[OwnerDashboard] Error in _routeUser: $e');
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _loadProperties(String uid) async {
    setState(() {
      _loadingProperties = true;
      _error = null;
    });

    try {
      // Use the robust query helper so we pick up properties stored under
      // different owner-field names (ownerId, owner.uid, owner).
      final docs = await _queryPropertyDocsForOwner(uid);
      _properties = docs.map((d) {
        final data = Map<String, dynamic>.from((d.data() as Map<String, dynamic>?) ?? {});
        data['id'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Failed to load properties: $e');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loadingProperties = false;
          if (_properties.isNotEmpty) _error = null;
        });
      }
    }
  }

  /// Query property documents for the given owner UID. This runs multiple
  /// queries to cope with historical schema differences where owner could be
  /// stored as 'ownerId', nested 'owner.uid' or as a top-level 'owner'.
  Future<List<QueryDocumentSnapshot>> _queryPropertyDocsForOwner(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final Map<String, QueryDocumentSnapshot> byId = {};

    try {
      // Preferred: ownerId with orderBy
      try {
        final snap = await firestore
            .collection('properties')
            .where('ownerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();
        for (var d in snap.docs) byId[d.id] = d;
      } catch (_) {
        // Fallback to ownerId without orderBy
        try {
          final snap = await firestore
              .collection('properties')
              .where('ownerId', isEqualTo: uid)
              .get();
          for (var d in snap.docs) byId[d.id] = d;
        } catch (_) {}
      }

      // Query nested owner.uid (documents that store owner as object)
      try {
        final snap2 = await firestore
            .collection('properties')
            .where('owner.uid', isEqualTo: uid)
            .get();
        debugPrint('[OwnerDashboard] query owner.uid -> ${snap2.docs.length}');
        for (var d in snap2.docs) byId[d.id] = d;
      } catch (_) {}

      // Query top-level owner field (string form)
      try {
        final snap3 = await firestore
            .collection('properties')
            .where('owner', isEqualTo: uid)
            .get();
        debugPrint('[OwnerDashboard] query owner -> ${snap3.docs.length}');
        for (var d in snap3.docs) byId[d.id] = d;
      } catch (_) {}

      // Some older/alternate schemas use 'userId' or 'createdBy' or 'hostId'
      for (final field in ['userId', 'createdBy', 'hostId']) {
        try {
          final snapX = await firestore.collection('properties').where(field, isEqualTo: uid).get();
          if (snapX.docs.isNotEmpty) debugPrint('[OwnerDashboard] query $field -> ${snapX.docs.length}');
          for (var d in snapX.docs) byId[d.id] = d;
        } catch (_) {}
      }

      // Some documents store owners as an array field 'owners'
      try {
        final snapArr = await firestore.collection('properties').where('owners', arrayContains: uid).get();
        debugPrint('[OwnerDashboard] query owners arrayContains -> ${snapArr.docs.length}');
        for (var d in snapArr.docs) byId[d.id] = d;
      } catch (_) {}
    } catch (e) {
      debugPrint('[OwnerDashboard] _queryPropertyDocsForOwner failed: $e');
    }

    return byId.values.toList();
  }

  Future<void> _populatePropertiesFromDocs(List<QueryDocumentSnapshot> docs) async {
    final list = docs.map((d) {
      final data = Map<String, dynamic>.from((d.data() as Map<String, dynamic>?) ?? {});
      data['id'] = d.id;
      return data;
    }).toList();

    if (mounted) {
      setState(() {
        _properties = list;
        _loadingProperties = false;
        if (_properties.isNotEmpty) _error = null;
      });

      // Debug: show a SnackBar in debug builds listing detected property ids
      if (kDebugMode) {
        final ids = _properties.map((p) => p['id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        final preview = ids.take(5).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected properties: ${_properties.length} (${preview}${ids.length>5? ', ...':''})'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } else {
      _properties = list;
    }
  }

  String get _addLabel {
    final c = _ownerCategory;
    if (c == null || c.isEmpty) return 'Add Property';
    final pretty = c.replaceAll('_', ' ');
    return 'Add ${pretty[0].toUpperCase()}${pretty.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 41, 70, 92),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'SKY',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'BASE',
                            style: TextStyle(color: Color(0xFFB9C5CC)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      ' "Host smarter. Earn better." ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color.fromARGB(255, 41, 70, 92), width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCOUNT MODE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 41, 70, 92),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'User Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        Switch(
                          value: true,
                          onChanged: (val) async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .update({'activeRole': val ? 'farmhouse_owner' : 'user'});
                            }

                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),

                        const Text(
                          'Owner Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 41, 70, 92),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color.fromARGB(255, 41, 70, 92), width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        'MENU',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color.fromARGB(255, 41, 70, 92),
                        ),
                      ),
                    ),

                    _DrawerTile(
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      selected: true,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                      builder: (context, snap) {
                        final count = snap.hasData ? snap.data!.docs.length : 0;
                        return Stack(
                          children: [
                            _DrawerTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Bookings',
                              selected: false,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => OwnerMainScaffold(initialIndex: 1),
                                  ),
                                );
                              },
                            ),
                            if (count > 0)
                              Positioned(
                                right: 20,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : count.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    _DrawerTile(
                      icon: Icons.star_outline,
                      label: 'Guest Reviews',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => OwnerMainScaffold(initialIndex: 2)),
                        );
                      },
                    ),

                    _DrawerTile(
                      icon: Icons.notifications_none,
                      label: 'Notifications',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OwnerNotificationsScreen()),
                        );
                      },
                    ),

                    _DrawerTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OwnerSettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_roles != null && _roles!.length > 1) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color.fromARGB(255, 41, 70, 92), width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'OWNER ACTIONS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 41, 70, 92),
                          ),
                        ),
                      ),

                      if (_roles != null && _roles!.contains('car_owner') && _activeRole != 'car_owner')
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: const BoxDecoration(),
                          child: _DrawerTile(
                            icon: Icons.directions_car_outlined,
                            label: 'Switch to Car Owner',
                            selected: false,
                            onTap: () async {
                              Navigator.pop(context);
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                  'activeRole': 'car_owner',
                                });
                              }
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const CarOwnerDashboard()),
                                );
                              }
                            },
                          ),
                        ),
                      if (_roles != null && _roles!.contains('farmhouse_owner') && _activeRole != 'farmhouse_owner')
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: const BoxDecoration(),
                          child: _DrawerTile(
                            icon: Icons.house_outlined,
                            label: 'Switch to Farmhouse Owner',
                            selected: false,
                            onTap: () async {
                              Navigator.pop(context);
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                  'activeRole': 'farmhouse_owner',
                                });
                              }
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const OwnerDashboard()),
                                );
                              }
                            },
                          ),
                        ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: const BoxDecoration(),
                        child: _DrawerTile(
                          icon: Icons.person_add_outlined,
                          label: 'Enroll as another owner',
                          selected: false,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: const [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'SKY',
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                        ),
                        const TextSpan(
                          text: 'BASE',
                          style: TextStyle(color: Color(0xFFB9C5CC)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Notifications button with unread badge
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snap) {
                      int unread = 0;
                      if (snap.hasData) unread = snap.data!.docs.length;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const OwnerNotificationsScreen()),
                              );
                            },
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                child: Center(
                                  child: Text(
                                    unread > 9 ? '9+' : unread.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('messages')
                        .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snap) {
                      final count = snap.hasData ? snap.data!.docs.length : 0;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MessagesScreen()),
                              );
                            },
                          ),
                          if (count > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : count.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  ' "Host smarter. Earn better." ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // ❌ REMOVE auto re-routing when properties list is empty
            // Instead show empty state UI
            if (!_checking && !_loadingProperties && _error == null && _properties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      'No properties yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add your first property to get started',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const add_screen.AddPropertyScreen()),
                        );
                      },
                      child: const Text('Add Property'),
                    ),
                  ],
                ),
              );
            }

            if (_checking) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_loadingProperties) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return Center(
                child: Text(
                  'Something went wrong. Please try again.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            // FALL THROUGH to real dashboard below
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720; // tablet/web breakpoint
                return RefreshIndicator(
                  onRefresh: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) await _loadProperties(user.uid);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // --- Welcome header ---
                      Builder(
                        builder: (context) {
              final name = (_ownerName != null && _ownerName!.trim().isNotEmpty)
                ? _ownerName!
                : (FirebaseAuth.instance.currentUser?.displayName != null && FirebaseAuth.instance.currentUser!.displayName!.trim().isNotEmpty)
                  ? FirebaseAuth.instance.currentUser!.displayName!
                  : 'Owner';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, $name',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Here's what's happening with your properties",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 41, 70, 92),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const add_screen.AddPropertyScreen()),
  );

  // If property was added, reload dashboard
  final user = FirebaseAuth.instance.currentUser;
  if (result == true && user != null) {
    await _loadProperties(user.uid);
  }
},
                          icon: const Icon(Icons.add),
                          label: Text(_addLabel),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Stats grid (2x2 on mobile, 4 in a row on wide screens) ---
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.9,
                        children: [
                          _StatCard(title: 'Total Properties', value: _totalProperties.toString()),
                          _StatCard(title: 'Active', value: _activeProperties.toString()),
                          _StatCard(title: 'Total Bookings', value: _totalBookings.toString()),
                          _StatCard(title: 'Total Earnings', value: '₹${_totalEarnings.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ===== ADMIN SUGGESTIONS =====
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('admin_suggestions')
                            .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                            .where('isRead', isEqualTo: false)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final docs = snapshot.data!.docs;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin Suggestions',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              ...docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final type = data['type'] ?? 'info';

                                Color bgColor;
                                if (type == 'warning') {
                                  bgColor = const Color(0xFFFFF3E0);
                                } else if (type == 'tip') {
                                  bgColor = const Color(0xFFE8F5E9);
                                } else {
                                  bgColor = const Color(0xFFE3F2FD);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Suggestion',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        data['message'] ?? '',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('admin_suggestions')
                                                .doc(doc.id)
                                                .update({'isRead': true});
                                          },
                                          child: const Text(
                                            'Mark as Read',
                                            style: TextStyle(
                                              color: Color.fromARGB(255, 41, 70, 92),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),


                      // --- Properties grid (1 card on small screens, 3 on wide) ---
                      const Text(
                        'Manage Properties',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color.fromARGB(255, 41, 70, 92),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'View, edit and track the status of all your listed properties',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ===== PROPERTY STATUS TABS =====
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _dashboardTabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _dashboardTabIndex == 0
                                        ? const Color.fromARGB(255, 41, 70, 92)
                                        : Colors.transparent,
                                    borderRadius:
                                        const BorderRadius.horizontal(left: Radius.circular(20)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Active',
                                      style: TextStyle(
                                        color: _dashboardTabIndex == 0
                                            ? Colors.white
                                            : const Color.fromARGB(255, 41, 70, 92),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _dashboardTabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  color: _dashboardTabIndex == 1
                                      ? const Color.fromARGB(255, 41, 70, 92)
                                      : Colors.transparent,
                                  child: Center(
                                    child: Text(
                                      'Inactive',
                                      style: TextStyle(
                                        color: _dashboardTabIndex == 1
                                            ? Colors.white
                                            : const Color.fromARGB(255, 41, 70, 92),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _dashboardTabIndex = 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _dashboardTabIndex == 2
                                        ? const Color.fromARGB(255, 41, 70, 92)
                                        : Colors.transparent,
                                    borderRadius:
                                        const BorderRadius.horizontal(right: Radius.circular(20)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Pending',
                                      style: TextStyle(
                                        color: _dashboardTabIndex == 2
                                            ? Colors.white
                                            : const Color.fromARGB(255, 41, 70, 92),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Builder(
                        builder: (context) {
                          final filtered = _properties.where((p) {
                            final status = (p['status'] ?? '').toString().toLowerCase();
                            final approved = p['adminApproved'] == true;

                            if (_dashboardTabIndex == 0) {
                              return approved && status == 'active';
                            }
                            if (_dashboardTabIndex == 1) {
                              return approved && status == 'inactive';
                            }
                            if (_dashboardTabIndex == 2) {
                              return !approved;
                            }
                            return true;
                          }).toList();

                          if (filtered.isEmpty) {
                            String message = 'No properties found';
                            if (_dashboardTabIndex == 0) message = 'No active properties';
                            if (_dashboardTabIndex == 1) message = 'No inactive properties';
                            if (_dashboardTabIndex == 2) message = 'No pending properties';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 3 : 1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              final photos = (p['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [];
                              final firstPhoto = photos.isNotEmpty ? photos.first : null;
                              final address = '${p['city'] ?? ''}, ${p['state'] ?? ''}'.trim();
                              final rating = (p['rating'] as num?)?.toDouble() ?? 0.0;
                              final views = (p['views'] as num?)?.toInt() ?? 0;

                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OwnerPropertyDetailScreen(property: p),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                          child: firstPhoto != null
                                              ? Image.network(firstPhoto, height: 160, width: double.infinity, fit: BoxFit.cover)
                                              : Container(height: 160, color: Colors.grey[200], child: const Icon(Icons.home, size: 48)),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Card(
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            child: IconButton(
                                              icon: const Icon(Icons.more_vert, color: Colors.black87),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                  ),
                                                  builder: (ctx) {
                                                    return SafeArea(
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          ListTile(
                                                            leading: const Icon(Icons.remove_red_eye_outlined),
                                                            title: const Text('View Details'),
                                                            onTap: () {
                                                              Navigator.pop(ctx);
                                                              Navigator.of(context).push(
                                                                MaterialPageRoute(
                                                                  builder: (_) => OwnerPropertyDetailScreen(property: p),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                          const Divider(height: 1),
                                                          ListTile(
                                                            leading: const Icon(Icons.edit_outlined),
                                                            title: const Text('Edit Property'),
                                                            onTap: () async {
                                                              Navigator.pop(ctx);

                                                              final propertyId = p['id'];

                                                              final result = await Navigator.of(context).push<Map<String, dynamic>?>(
                                                                MaterialPageRoute(
                                                                  builder: (_) => edit_screen.EditPropertyScreen(
                                                                    existingData: p,
                                                                    propertyId: propertyId,
                                                                  ),
                                                                ),
                                                              );

                                                              if (result == null) return;

                                                              final Map<String, dynamic> changedFields = result;

                                                              if (changedFields.isEmpty) {
                                                                if (context.mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    const SnackBar(content: Text('No changes detected')),
                                                                  );
                                                                }
                                                                return;
                                                              }

                                                              final uid = FirebaseAuth.instance.currentUser?.uid;
                                                              if (propertyId == null || uid == null) return;

                                                              try {
                                                                await FirebaseFirestore.instance.collection('property_edits').add({
                                                                  'propertyId': propertyId,
                                                                  'ownerId': uid,
                                                                  'oldData': p,
                                                                  'updatedData': changedFields, // ✅ only changed fields
                                                                  'status': 'pending',
                                                                  'createdAt': FieldValue.serverTimestamp(),
                                                                });

                                                                // mark property as pending update
                                                                await FirebaseFirestore.instance
                                                                    .collection('properties')
                                                                    .doc(propertyId)
                                                                    .update({'status': 'pending_update'});

                                                                if (context.mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    const SnackBar(content: Text('Changes submitted for admin approval')),
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                if (context.mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(content: Text('Failed: $e')),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                          ),
                                                          const Divider(height: 1),
                                                          ListTile(
                                                            leading: const Icon(Icons.delete_outline, color: Colors.red),
                                                            title: const Text(
                                                              'Delete Property',
                                                              style: TextStyle(color: Colors.red),
                                                            ),
                                                            onTap: () async {
                                                              Navigator.pop(ctx);

                                                              final confirm = await showDialog<bool>(
                                                                context: context,
                                                                builder: (c) => AlertDialog(
                                                                  title: const Text('Delete Property'),
                                                                  content: const Text('This action cannot be undone.'),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(c, false),
                                                                      child: const Text('Cancel'),
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed: () => Navigator.pop(c, true),
                                                                      child: const Text('Delete'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );

                                                              if (confirm == true) {
                                                                final id = p['id'];
                                                                if (id != null) {
                                                                  await FirebaseFirestore.instance
                                                                      .collection('properties')
                                                                      .doc(id)
                                                                      .delete();

                                                                  setState(() {
                                                                    _properties.removeWhere((prop) => prop['id'] == id);
                                                                  });
                                                                }
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color.fromARGB(255, 41, 70, 92)),
                                          ),
                                          child: Text(p['propertyType'] ?? '', style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 41, 70, 92), fontWeight: FontWeight.w600,)),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(p['propertyName'] ?? 'Unnamed property', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, ), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Row(children: [const Icon(Icons.location_on, size: 14), const SizedBox(width: 4), Expanded(child: Text(address, style: const TextStyle(fontSize: 13, ), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                                              const SizedBox(width: 4),
                                              Text('${p['totalBookings'] ?? 0} bookings', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                            ]),
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Icons.remove_red_eye, size: 14, color: Colors.purple),
                                              Text(' $views', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                            ]),
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Icons.star, size: 14, color: Colors.amber),
                                              Text(' ${rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                            ]),
                                          ],
                                        ),
                                      ]),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ]),
                  ),
                );
              },
            );
            }
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;

  const _StatCard({
    required this.title,
    required this.value,
    this.highlight=false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(
                colors: [Color.fromARGB(255, 41, 70, 92), Color.fromARGB(255, 41, 70, 92)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlight ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 41, 70, 92),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: highlight ? Colors.white70 : const Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: highlight ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ]),
    );
  }
}



class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? const Color.fromARGB(255, 41, 70, 92) : Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyPropertiesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  final String? category;
  const MyPropertiesScreen({super.key, required this.properties, this.category});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  late Map<String, bool> _activeStates;
  late List<Map<String, dynamic>> _props; // local list for animated removal
  // Local animated list key and deleting tracker removed (not used).
  int _tabIndex = 0; // 0 = Active, 1 = Inactive, 2 = Pending

  @override
  void initState() {
    super.initState();
    // local mutable copy for animations
    _props = List<Map<String, dynamic>>.from(widget.properties);
    _activeStates = {};
    for (var p in _props) {
      final id = p['id'] as String?;
      if (id != null) {
        _activeStates[id] = (p['status'] ?? '').toString().toLowerCase() == 'active';
      }
    }
  }

  void _showPropertyMenu(BuildContext context, Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye_outlined),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OwnerPropertyDetailScreen(property: p),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Property'),
                onTap: () async {
                  Navigator.pop(ctx);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Edit Property'),
                      content: const Text(
                        'Are you sure you want to edit this property?\n\nAll changes will require admin approval before becoming visible.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  final id = p['id'] as String?;
                  final result = await Navigator.of(context).push<bool?>(
                    MaterialPageRoute(
                      builder: (_) => edit_screen.EditPropertyScreen(
                        existingData: p,
                        propertyId: id ?? '',
                      ),
                    ),
                  );

                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Editing submitted successfully. Changes will reflect after admin approval.',
                        ),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);

                  final id = p['id'] as String?;
                  if (id == null) return;

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete this property?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  try {
                    await FirebaseFirestore.instance
                        .collection('properties')
                        .doc(id)
                        .delete();

                    setState(() {
                      _props.removeWhere((e) => e['id'] == id);
                      _activeStates.remove(id);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Property deleted')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Delete failed: $e')),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
  // _addLabel removed (not used in this screen)

  @override
  Widget build(BuildContext context) {
  // Removed unused local summary variables (total, active, bookings, ratings)

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Manage Properties',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color.fromARGB(255, 41, 70, 92),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage and track all your listed properties',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.person_outline, color: Colors.black54),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== FILTER TABS =====
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? const Color.fromARGB(255, 41, 70, 92) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                          child: Center(
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: _tabIndex == 0 ? Colors.white : const Color.fromARGB(255, 41, 70, 92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          color: _tabIndex == 1 ? const Color.fromARGB(255, 41, 70, 92) : Colors.transparent,
                          child: Center(
                            child: Text(
                              'Inactive',
                              style: TextStyle(
                                color: _tabIndex == 1 ? Colors.white : const Color.fromARGB(255, 41, 70, 92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 2 ? const Color.fromARGB(255, 41, 70, 92) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                          ),
                          child: Center(
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                color: _tabIndex == 2 ? Colors.white : const Color.fromARGB(255, 41, 70, 92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== FILTERED PROPERTIES =====
              Builder(
                builder: (context) {
                  final filtered = _props.where((p) {
                    final status = (p['status'] ?? '').toString().toLowerCase();
                    final approved = p['adminApproved'] == true;

                    if (_tabIndex == 0) {
                      return approved && status == 'active';
                    }
                    if (_tabIndex == 1) {
                      return approved && status == 'inactive';
                    }
                    if (_tabIndex == 2) {
                      return !approved;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    String message = 'No properties found';
                    if (_tabIndex == 0) message = 'No active properties';
                    if (_tabIndex == 1) message = 'No inactive properties';
                    if (_tabIndex == 2) message = 'No pending properties';

                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filtered.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPropertyCard(p),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final photos = (p['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [];
    final address = '${p['city'] ?? ''}, ${p['state'] ?? ''}'.trim();
    final rating = (p['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = (p['reviewCount'] as num?)?.toInt() ?? 0;
    final views = (p['views'] as num?)?.toInt() ?? 0;
    final isActive = _activeStates[p['id']] ?? false;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: photos.isNotEmpty
        ? Image.network(photos.first, height: 200, width: double.infinity, fit: BoxFit.cover)
        : Container(height: 200, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.home, size: 60)),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color:const Color.fromARGB(255, 41, 70, 92), borderRadius: BorderRadius.circular(20)),
              child: Text(isActive ? 'active' : 'inactive', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onPressed: () => _showPropertyMenu(context, p),
              ),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color.fromARGB(255, 41, 70, 92)),
                ),
                child: Text(
                  p['propertyType'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 41, 70, 92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(p['propertyName'] ?? 'Unnamed property', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color.fromARGB(255, 41, 70, 92)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(address)),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [const Icon(Icons.star, size: 16, color: Colors.amber), Text(' ${rating.toStringAsFixed(1)} ($reviews)'), const SizedBox(width: 12), const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey), Text(' $views')]),
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: const [Icon(Icons.calendar_today, size: 16, color: Colors.blue), SizedBox(width: 6), Text('Bookings', style: TextStyle(fontWeight: FontWeight.w600))]), Text((p['totalBookings'] ?? 0).toString())]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: const [Icon(Icons.attach_money, size: 16, color: Color.fromARGB(255, 41, 70, 92)), SizedBox(width: 6), Text('Revenue', style: TextStyle(fontWeight: FontWeight.w600))]), Text('₹${p['revenue'] ?? (p['pricePerNight'] ?? 0) * (p['totalBookings'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color.fromARGB(255, 41, 70, 92)))]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Price per night', style: TextStyle(color: Color(0xFF64748B))), Text('₹${p['pricePerNight'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w500))]),
              const Divider(height: 20),
              // --- Active Listing Toggle ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Listing', style: TextStyle(fontWeight: FontWeight.w600)),
                  Switch(
                    value: isActive,
                    onChanged: (v) async {
                      final id = p['id'] as String?;
                      if (id == null) return;
                      setState(() => _activeStates[id] = v);
                      try {
                        await FirebaseFirestore.instance.collection('properties').doc(id).update({'status': v ? 'active' : 'inactive'});
                      } catch (e) {
                        setState(() => _activeStates[id] = !v);
                      }
                    },
                  ),
                ],
              ),
              // --- Last Minute Deal Toggle ---
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Last Minute Deal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: p['isLastMinuteDeal'] ?? false,
                    onChanged: (v) async {
                      final id = p['id'] as String?;
                      if (id == null) return;

                      final validTill = DateTime.now().add(const Duration(days: 1));

                      await FirebaseFirestore.instance
                          .collection('properties')
                          .doc(id)
                          .update({
                        'isLastMinuteDeal': v,
                        if (v) 'lastMinuteDiscount': p['lastMinuteDiscount'] ?? 20,
                        if (v) 'lastMinuteValidTill': Timestamp.fromDate(validTill),
                      });

                      setState(() {
                        p['isLastMinuteDeal'] = v;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (p['isLastMinuteDeal'] == true)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      final id = p['id'] as String?;
                      if (id == null) return;

                      final controller = TextEditingController(
                        text: (p['lastMinuteDiscount'] ?? 20).toString(),
                      );

                      final result = await showDialog<int>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Set Discount %'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Enter discount percentage',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final value = int.tryParse(controller.text);
                                Navigator.pop(ctx, value);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );

                      if (result != null && result > 0) {
                        await FirebaseFirestore.instance
                            .collection('properties')
                            .doc(id)
                            .update({
                          'lastMinuteDiscount': result,
                        });

                        setState(() {
                          p['lastMinuteDiscount'] = result;
                        });
                      }
                    },
                    child: Text(
                      'Edit Discount (${p['lastMinuteDiscount'] ?? 20}%)',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 41, 70, 92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}


class OwnerPropertyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> property;
  const OwnerPropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final photos = (property['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [];
  // firstPhoto removed; use photos list directly where needed

    final pricePerNight = property['pricePerNight'] ?? 0;
    final revenue = property['revenue'] ?? 0;
    final status = (property['status'] ?? 'inactive').toString();

    final address = '${property['city'] ?? ''}, ${property['state'] ?? ''}'.trim();
    final rating = (property['rating'] as num?)?.toDouble() ?? 0.0;
    final bookings = property['totalBookings'] ?? 0;
    final views = property['views'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: const Color.fromARGB(255, 41, 70, 92),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [

          // PHOTO GALLERY
          SizedBox(
            height: 240,
            child: photos.isEmpty
                ? Container(
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.home, size: 60)),
                  )
                : PageView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // PROPERTY TYPE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color.fromARGB(255, 41, 70, 92)),
                  ),
                  child: Text(
                    property['propertyType'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 41, 70, 92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // PROPERTY NAME
                Text(
                  property['propertyName'] ?? 'Property',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // LOCATION
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 6),
                    Text(address),
                  ],
                ),

                const SizedBox(height: 16),

                // STATS ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(Icons.calendar_today, bookings.toString(), "Bookings"),
                    _stat(Icons.remove_red_eye, views.toString(), "Views"),
                    _stat(Icons.star, rating.toStringAsFixed(1), "Rating"),
                  ],
                ),

                const SizedBox(height: 20),

                // OWNER ANALYTICS
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Owner Analytics",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _stat(Icons.attach_money, '₹$revenue', "Revenue"),
                          _stat(Icons.hotel, '₹$pricePerNight', "Per Night"),
                          _stat(
                            Icons.toggle_on,
                            status.toUpperCase(),
                            "Status",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // EDIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 41, 70, 92),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit this property"),
                    onPressed: () {
                      final id = property['id'] as String? ?? '';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => edit_screen.EditPropertyScreen(existingData: property, propertyId: id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
// Messages and chat UI moved to `lib/screens/owner_messages_screen.dart`.



class GuestReviewsScreen extends StatefulWidget {
  const GuestReviewsScreen({super.key});

  @override
  State<GuestReviewsScreen> createState() => _GuestReviewsScreenState();
}

class _GuestReviewsScreenState extends State<GuestReviewsScreen> {
  int _tabIndex = 0; // 0 = All, 1 = Pending, 2 = Responded

  @override
  void initState() {
    super.initState();
    _setupReviewNotifications();
  }

  Future<void> _setupReviewNotifications() async {
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();

    // FirebaseMessaging.onMessage.listen((dynamic message) {
    //   if (!mounted) return;
    //   if (message.data['type'] == 'new_review') {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('New guest review received')),
    //     );
    //     setState(() {}); // refresh StreamBuilders on this screen
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF6FAF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Manage and respond to guest feedback',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            // ===== TOP METRICS CARDS =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Average Rating', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    SizedBox(height: 6),
                    Text('4.3', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  ]),
                  Icon(Icons.star, color: Colors.amber, size: 32),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Total Reviews', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    SizedBox(height: 6),
                    Text('4', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pending Response', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    SizedBox(height: 6),
                    Text('2', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Response Rate', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                SizedBox(height: 6),
                Text('50%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),

            // ===== TABS =====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _tabIndex == 0 ? const Color(0xFF1E5FA8) : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text('All Reviews (4)', style: TextStyle(color: _tabIndex == 0 ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      color: _tabIndex == 1 ? const Color(0xFFE3F2FD) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Center(child: Text('Pending (2)', style: TextStyle(fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _tabIndex == 2 ? const Color(0xFFE3F2FD) : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Center(child: Text('Responded (2)', style: TextStyle(fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ===== REAL REVIEWS FROM FIRESTORE =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('review_replies')
                  .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No reviews responded yet. Pending reviews will appear here soon.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _ReviewCard(
                      name: data['guestName'] ?? 'Guest',
                      property: data['propertyName'] ?? '',
                      date: (data['createdAt'] as Timestamp?)?.toDate().toString().split(' ').first ?? '',
                      rating: 4.0,
                      text: data['replyText'] ?? '',
                      hasResponse: true,
                      response: data['replyText'],
                    );
                  },
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String property;
  final String date;
  final double rating;
  final String text;
  final bool hasResponse;
  final String? response;

  const _ReviewCard({
    required this.name,
    required this.property,
    required this.date,
    required this.rating,
    required this.text,
    this.hasResponse = false,
    this.response,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(radius: 22, child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(property, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(8)),
              child: Text(rating.toStringAsFixed(1)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(text),
          const SizedBox(height: 8),
          const Row(children: [Icon(Icons.thumb_up_outlined, size: 16), SizedBox(width: 6), Text('Helpful (12)')]),
          if (hasResponse && response != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF0FFF6), borderRadius: BorderRadius.circular(12)),
              child: Text(response!),
            ),
          ] else ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewReplyScreen(
                      guestName: name,
                      propertyName: property,
                    ),
                  ),
                );
              },
              child: const Text('Reply to Review'),
            ),
          ]
        ]),
      ),
    );
  }
}

class ReviewReplyScreen extends StatefulWidget {
  final String guestName;
  final String propertyName;

  const ReviewReplyScreen({
    super.key,
    required this.guestName,
    required this.propertyName,
  });

  @override
  State<ReviewReplyScreen> createState() => _ReviewReplyScreenState();
}

class _ReviewReplyScreenState extends State<ReviewReplyScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reply to Review'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF6FAF8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Replying to: ${widget.guestName}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(widget.propertyName, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Write your response here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final text = _controller.text.trim();
                                    if (text.isEmpty) return;
                                    setState(() => _submitting = true);
                                    try {
                                      await FirebaseFirestore.instance.collection('review_replies').add({
                                        'guestName': widget.guestName,
                                        'propertyName': widget.propertyName,
                                        'replyText': text,
                                        'ownerId': FirebaseAuth.instance.currentUser?.uid,
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      if (context.mounted) Navigator.pop(context);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to send reply: $e')),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => _submitting = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 41, 70, 92),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Send Reply'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            );
          }
        }

// _BottomCurveClipper removed — header now uses a rounded Container matching HomeScreen

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color.fromARGB(255, 41, 70, 92),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Text(
              'Profile Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 41, 70, 92),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}