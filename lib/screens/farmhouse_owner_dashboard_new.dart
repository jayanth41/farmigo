import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/owner_side_menu.dart';

/// Farmhouse Owner Dashboard
/// Main dashboard for farmhouse owners showing overview and key metrics
class FarmhouseOwnerDashboardNew extends StatefulWidget {
  const FarmhouseOwnerDashboardNew({super.key});

  @override
  State<FarmhouseOwnerDashboardNew> createState() =>
      _FarmhouseOwnerDashboardNewState();
}

class _FarmhouseOwnerDashboardNewState
    extends State<FarmhouseOwnerDashboardNew> {
  String? _ownerName;
  String? _ownerEmail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('owners')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _ownerName = doc['name'] ?? 'Owner';
            _ownerEmail = user.email ?? 'email@example.com';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
      debugPrint('Error loading owner data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmhouse Owner Dashboard'),
        elevation: 0,
      ),
      drawer: OwnerSideMenu(
        ownerName: _ownerName,
        ownerEmail: _ownerEmail,
        activeRole: 'farmhouse',
        currentScreen: 'home',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_ownerName ?? "Owner"}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Here\'s an overview of your farmhouse management',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.domain,
                    title: 'Properties',
                    value: '0',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    title: 'Bookings',
                    value: '0',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    title: 'Rating',
                    value: '0.0',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money,
                    title: 'Revenue',
                    value: '₹0',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildQuickActionTile(
                  icon: Icons.add_home,
                  label: 'Add Property',
                  onTap: () {},
                ),
                _buildQuickActionTile(
                  icon: Icons.analytics,
                  label: 'View Analytics',
                  onTap: () {},
                ),
                _buildQuickActionTile(
                  icon: Icons.people,
                  label: 'Manage Bookings',
                  onTap: () {},
                ),
                _buildQuickActionTile(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
