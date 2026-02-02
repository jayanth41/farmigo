import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('You are browsing as guest', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Login')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("Bookings", "12"),
        _buildStatItem("Favorites", "5"),
        _buildStatItem("Rewards", "1500"),
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

  Widget _buildEditProfileForm() => const SizedBox.shrink();
}
