// NOTE: place logo at: assets/skybase_logo.png
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// Adjust these paths if your files are in a different folder
import 'add_property_screen.dart';
import 'owner_onboarding_screen.dart';
import 'manage_bookings.dart';
import 'owner_analytics_screen.dart';
import 'owner_settings_screen.dart';
import 'home_screen.dart';
import 'car_owner_dashboard_new.dart';
import 'role_selection_screen.dart';

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

  int get _totalProperties => _properties.length;
  int get _activeProperties => _properties.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'active').length;
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
      // Pop back to previous screen (Home) instead of staying
      Navigator.of(context).pop();
      return;
    }

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Get user roles and activeRole
      final userSnap = await firestore.collection('users').doc(uid).get();
      final roles = List<String>.from(userSnap.data()?['roles'] ?? []);
      final activeRole = userSnap.data()?['activeRole'] as String?;
      final displayName = userSnap.data()?['displayName'] as String? ?? userSnap.data()?['fullName'] as String? ?? 'Owner';
      
      if (mounted) setState(() => _ownerName = displayName);
      debugPrint('[OwnerDashboard] Owner name: $_ownerName');

      // NEW RULE: if activeRole is null AND the user has at least one owner role,
      // always ask them to select a role first.
      if (activeRole == null && roles.isNotEmpty) {
        debugPrint('[OwnerDashboard] activeRole is null — forcing RoleSelectionScreen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => RoleSelectionScreen(roles: roles)),
          );
        }
        return;
      }

      // NEW USER CASE: logged in but not yet an owner
      final userRole = userSnap.data()?['role'] as String? ?? 'user';
      if (userRole == 'user' || roles.isEmpty) {
        debugPrint('[OwnerDashboard] New/normal user — redirecting to onboarding');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen()),
          );
        }
        return;
      }

      if (mounted) setState(() => _roles = roles);
      debugPrint('[OwnerDashboard] User roles: $roles, activeRole: $activeRole');

      if (!mounted) return;

      // ROUTE BASED ON ROLES FIRST (not properties)
      
      // CASE-3: If user is ONLY car_owner (single role), go to CarOwnerDashboard
      if (roles.length == 1 && roles.contains('car_owner')) {
        debugPrint('[OwnerDashboard] CASE-3: Single car_owner role, redirecting to CarOwnerDashboard');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CarOwnerDashboard()),
        );
        return;
      }

      // CASE-2: If user is ONLY farmhouse_owner, check for properties
      if (roles.length == 1 && roles.contains('farmhouse_owner')) {
        debugPrint('[OwnerDashboard] CASE-2: Single farmhouse_owner role');
        
        // Check if user has properties
        final propsSnap = await firestore
            .collection('properties')
            .where('ownerId', isEqualTo: uid)
            .limit(1)
            .get();
        final hasProperty = propsSnap.docs.isNotEmpty;
        debugPrint('[OwnerDashboard] farmhouse_owner has property: $hasProperty');

        if (!mounted) return;

        if (!hasProperty) {
          debugPrint('[OwnerDashboard] No properties, redirecting to AddPropertyScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
          return;
        }

        debugPrint('[OwnerDashboard] Loading dashboard');
        setState(() => _checking = false);
        await _loadProperties(uid);
        return;
      }

      // CASE-4: If user has MULTIPLE roles
      if (roles.length > 1) {
        // 4B: If activeRole is car_owner, go to CarOwnerDashboard
        if (activeRole == 'car_owner') {
          debugPrint('[OwnerDashboard] CASE-4B: Multiple roles, activeRole=car_owner, redirecting to CarOwnerDashboard');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CarOwnerDashboard()),
          );
          return;
        }

        // 4C: If activeRole is farmhouse_owner, check for properties then load dashboard
        if (activeRole == 'farmhouse_owner') {
          debugPrint('[OwnerDashboard] CASE-4C: Multiple roles, activeRole=farmhouse_owner');
          
          // Check if user has properties
          final propsSnap = await firestore
              .collection('properties')
              .where('ownerId', isEqualTo: uid)
              .limit(1)
              .get();
          final hasProperty = propsSnap.docs.isNotEmpty;
          debugPrint('[OwnerDashboard] farmhouse_owner has property: $hasProperty');

          if (!mounted) return;

          if (!hasProperty) {
            debugPrint('[OwnerDashboard] No properties, redirecting to AddPropertyScreen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
            );
            return;
          }

          setState(() => _checking = false);
          await _loadProperties(uid);
          return;
        }
      }

      // Fallback: if somehow we reach here, treat as verified owner with no properties
      debugPrint('[OwnerDashboard] Fallback reached — sending to AddPropertyScreen');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
        );
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
      // Try ordered query first (preferred), fall back to unordered if Firestore rejects ordering
      try {
        final snap = await FirebaseFirestore.instance
            .collection('properties')
            .where('ownerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();

        _properties = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
      } catch (e) {
        debugPrint('Ordered query failed, retrying without orderBy: $e');
        final snap = await FirebaseFirestore.instance
            .collection('properties')
            .where('ownerId', isEqualTo: uid)
            .get();

        _properties = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
      }
    } catch (e) {
      debugPrint('Failed to load properties: $e');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loadingProperties = false;
          // If an error happened but we still have properties, clear the error
          if (_properties.isNotEmpty) _error = null;
        });
      }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset('assets/images/skybase_logo.png', height: 28, fit: BoxFit.cover, alignment: Alignment.center),
                    ),
                    const SizedBox(width: 8),
                    const Text('Skybase',
                        style: TextStyle(
                          color:  Color.fromARGB(255, 41, 70, 92),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: true,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.calendar_today_outlined,
                label: 'Bookings',
                selected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManageBookingsScreen()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.message_outlined,
                label: 'Messages',
                selected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.star_outline,
                label: 'Guest Reviews',
                selected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GuestReviewsScreen()),
                  );
                },
              ),
              if (_roles != null && _roles!.length > 1) ...[
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('OWNER ACTIONS', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),

                _DrawerTile(
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

                _DrawerTile(
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
              ],

              _DrawerTile(
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

              _DrawerTile(
                icon: Icons.logout_outlined,
                label: 'Logout',
                selected: false,
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
              ),
              const Spacer(),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Version 1.0', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: 16,
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset('assets/images/skybase_logo.png', height: 22, fit: BoxFit.cover, alignment: Alignment.center),
          ),
          SizedBox(width: 8),
          Text('Skybase', style: TextStyle(color: Color(0xFF1E5FA8), fontWeight: FontWeight.bold,)),
        ]),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.person_outline, color: Colors.black54),
          )
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // If we reach here with no properties, treat it as "no properties" state
            // rather than a broken screen — route back through _routeUser().
            if (!_checking && !_loadingProperties && _error == null && _properties.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _routeUser());
              return const Center(child: CircularProgressIndicator());
            }

            if (_checking) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_loadingProperties) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              // If there's an error loading properties, treat it as "no properties" and go to AddPropertyScreen
              debugPrint('[OwnerDashboard] Error loading properties, redirecting to AddPropertyScreen');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                );
              });
              return const SizedBox.shrink();
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
                      Text('Welcome back, ${_ownerName ?? 'Owner'}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      const Text('Here\'s what\'s happening with your properties.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
    MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
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
                          _StatCard(title: 'Active', value: _activeProperties.toString(), highlight: true),
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

                      const SizedBox(height: 20),
                      _QuickActionsSection(),
                      const SizedBox(height: 20),

                      // --- Properties grid (1 card on small screens, 3 on wide) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your Properties', style: Theme.of(context).textTheme.titleSmall),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MyPropertiesScreen(
                                    properties: _properties,
                                    category: _ownerCategory,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: Color.fromARGB(255, 41, 70, 92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: _properties.length > 3 ? 3 : _properties.length,
                        itemBuilder: (context, index) {
                          final p = _properties[index];
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
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                  child: firstPhoto != null
                                      ? Image.network(firstPhoto, height: 160, width: double.infinity, fit: BoxFit.cover)
                                      : Container(height: 160, color: Colors.grey[200], child: const Icon(Icons.home, size: 48)),
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

  const _StatCard({required this.title, required this.value, this.highlight = false});

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


class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color.fromARGB(255, 41, 70, 92), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _QuickActionTile(icon: Icons.add_home, label: 'Add New Property', onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
        }),
        const SizedBox(height: 4),
        _QuickActionTile(icon: Icons.calendar_today, label: 'Manage Bookings', onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageBookingsScreen()));
        }),
        const SizedBox(height: 4),
        _QuickActionTile(icon: Icons.analytics, label: 'View Analytics', onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OwnerAnalyticsScreen()));
        }),
        const SizedBox(height: 4),
        _QuickActionTile(icon: Icons.settings, label: 'Property Settings', onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OwnerSettingsScreen()));
        }),
      ]),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
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
      color: selected ? const Color(0xFFE3F2FD) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: selected ? const Color.fromARGB(255, 41, 70, 92) : Colors.black54),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? const Color.fromARGB(255, 41, 70, 92) : Colors.black87,
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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Set<String> _deletingIds = {}; // track loading states
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
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddPropertyScreen(),
                    ),
                  );
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
  String _addLabel() {
    final c = widget.category;
    if (c == null || c.isEmpty) return 'Add Property';
    final pretty = c.replaceAll('_', ' ');
    return 'Add ${pretty[0].toUpperCase()}${pretty.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.properties.length;
    final active = widget.properties.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'active').length;
    final bookings = widget.properties.fold<int>(0, (sum, p) => sum + ((p['totalBookings'] as num?)?.toInt() ?? 0));
    final ratings = widget.properties.map((p) => (p['rating'] as num?)?.toDouble()).whereType<double>().toList();
    final avgRating = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;

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
    final firstPhoto = photos.isNotEmpty ? photos.first : null;
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
            child: firstPhoto != null
                ? Image.network(firstPhoto, height: 200, width: double.infinity, fit: BoxFit.cover)
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
    final firstPhoto = photos.isNotEmpty ? photos.first : null;

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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddPropertyScreen(),
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

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    _listenForMessageNotifications();
  }

  void _listenForMessageNotifications() async {
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();

    // FirebaseMessaging.onMessage.listen((dynamic message) {
    //   if (message.data['type'] == 'new_message') {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('New message received')),
    //     );
    //     setState(() {});
    //   }
    // });
  }
  int _tabIndex = 0; // 0 = Active, 1 = Archived
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF8),
      appBar: AppBar(
        title: const Text('Messages'),
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black54),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Chat with your guests and manage inquiries',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? const Color(0xFFE3F2FD) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: const Center(
                            child: Text('Active (2)', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tabIndex == 1 ? const Color(0xFFE3F2FD) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: const Center(
                            child: Text('Archived (1)', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _tabIndex == 0
                  ? StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('conversations')
                          .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('archived', isEqualTo: false)
                          .orderBy('updatedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No active conversations'));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ConversationTile(
                      name: data['guestName'] ?? 'Guest',
                      conversationId: doc.id,
                      subtitle: '${data['propertyName'] ?? ''}\n${data['lastMessage'] ?? ''}',
                      time: data['lastSeenText'] ?? '',
                      avatarUrl: '',
                      activeTag: data['activeBooking'] == true,
                      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
                    ),
                  );
                          },
                        );
                      },
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('conversations')
                          .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('archived', isEqualTo: true)
                          .orderBy('updatedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No archived conversations'));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ConversationTile(
                      name: data['guestName'] ?? 'Guest',
                      conversationId: doc.id,
                      subtitle: data['propertyName'] ?? '',
                      time: data['lastSeenText'] ?? '',
                      avatarUrl: '',
                      activeTag: false,
                      unreadCount: 0,
                    ),
                  );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String conversationId;
  final String subtitle;
  final String time;
  final String avatarUrl;
  final bool activeTag;
  final int unreadCount;

  const _ConversationTile({
    required this.name,
    required this.conversationId,
    required this.subtitle,
    required this.time,
    required this.avatarUrl,
    this.activeTag = false,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              contactName: name,
              conversationId: conversationId,
            ),
          ),
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE3F2FD),
                child: const Icon(Icons.person_outline, color: Color.fromARGB(255, 41, 70, 92)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:const Color.fromARGB(255, 41, 70, 92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (activeTag)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Active Booking', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String conversationId;
  const ChatScreen({super.key, required this.contactName, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenForMessageNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archive conversation',
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .update({'archived': true});
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .doc(widget.conversationId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final d = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final photo = (d['propertyPhoto'] as String?) ?? '';
              final start = d['checkIn'] ?? '';
              final end = d['checkOut'] ?? '';
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: photo.isEmpty
                          ? Container(width: 64, height: 64, color: Colors.grey[200], child: const Icon(Icons.home))
                          : Image.network(photo, width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['propertyName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Check-in: $start', style: const TextStyle(fontSize: 12)),
                          Text('Check-out: $end', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data() as Map<String, dynamic>;
                    final isOwner = m['from'] == 'owner';
                    return Align(
                      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
                      child: Chip(label: Text(m['text'] ?? '')),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 41, 70, 92)),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(widget.conversationId)
                        .collection('messages')
                        .add({
                      'text': text,
                      'from': 'owner',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    await FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(widget.conversationId)
                        .update({
                      'lastMessage': text,
                      'updatedAt': FieldValue.serverTimestamp(),
                      'unreadCount': 0,
                    });
                    _controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _listenForMessageNotifications() {
    // Placeholder for FCM: when a new message arrives for this conversation,
    // increment unreadCount in Firestore and trigger a local notification.
    // This will be wired to FirebaseMessaging later.
  }
}



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
