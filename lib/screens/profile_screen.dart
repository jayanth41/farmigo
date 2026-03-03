import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/favorites_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userDoc;
  bool _loading = true;
  late FavoritesController _favoritesController;
  // Real-time stats: we'll use StreamBuilders directly on Firestore collections/docs

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    _favoritesController = Get.find<FavoritesController>();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }
  // (No long-lived listeners here; StreamBuilders will subscribe/unsubscribe automatically.)

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 41, 70, 92),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildStatsCounter(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final changed = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );
                        if (changed == true) await _loadUser();
                      },
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Always-visible button to complete owner details. Navigates to
                  // OwnerDetailsScreen where users can fill owner-related fields.
                 
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _auth.signOut();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _userDoc = null;
        _loading = false;
      });
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      _userDoc = doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Failed to load user doc: $e');
      _userDoc = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  // ---------------- HEADER ----------------

  Widget _buildProfileHeader() {
    final user = _auth.currentUser;
    final photoUrl = _userDoc?['photoUrl'] as String? ?? user?.photoURL;
    final displayName = _userDoc?['name'] as String? ?? user?.displayName ?? '';
    final email = _userDoc?['email'] as String? ?? user?.email ?? '';
    final phone = _userDoc?['phone'] as String? ?? user?.phoneNumber ?? '';

    return Row(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: (photoUrl == null || photoUrl.isEmpty) ? Text(displayName.isNotEmpty ? displayName[0] : 'U', style: const TextStyle(fontSize: 36)) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName.isNotEmpty ? displayName : 'No name', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (email.isNotEmpty) Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
              if (phone.isNotEmpty) Text(phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCounter() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      );
    }

    final uid = user.uid;
    // Bookings and rewards can remain real-time via Firestore; favorites are
    // driven by the shared FavoritesController so the UI stays in sync.
    final bookingsStream = _firestore.collection('users').doc(uid).collection('bookings').snapshots();
    final userDocStream = _firestore.collection('users').doc(uid).snapshots();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Bookings count (real-time)
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: bookingsStream,
          builder: (context, snap) {
            final bookings = snap.hasData ? snap.data!.size : 0;
            return _buildStatItem("Bookings", bookings.toString());
          },
        ),

        // Favorites count (reactive via controller)
        Obx(() {
          final favCount = _favoritesController.favorites.length;
          return _buildStatItem("Favorites", favCount.toString());
        }),

        // Rewards from users/{uid} doc (real-time)
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, snap) {
            int rewards = 0;
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data();
              final rp = data?['rewardPoints'];
              if (rp is int) {
                rewards = rp;
              } else if (rp is num) rewards = rp.toInt();
              else if (rp is String) rewards = int.tryParse(rp) ?? 0;
            }
            return _buildStatItem("Rewards", rewards.toString());
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14)),
      ],
    );
  }

  // ---------------- EDIT FORM ----------------
  // (Previously an unused helper was here; removed to keep code clean.)
}
