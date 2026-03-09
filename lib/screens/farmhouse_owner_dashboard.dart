import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer_with_roles.dart';

/// Farmhouse Owner Dashboard
/// Shows farmhouse properties and booking management
class FarmhouseOwnerDashboard extends StatefulWidget {
  const FarmhouseOwnerDashboard({super.key});

  @override
  State<FarmhouseOwnerDashboard> createState() =>
      _FarmhouseOwnerDashboardState();
}

class _FarmhouseOwnerDashboardState extends State<FarmhouseOwnerDashboard> {
  late String _uid;
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();

      // Fetch user's farmhouse properties
      final propertiesSnap = await FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: _uid)
          .where('category', isEqualTo: 'farmhouse')
          .get();

      final properties = propertiesSnap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Count active bookings
      int totalBookings = 0;
      for (var prop in properties) {
        final bookingsSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('propertyId', isEqualTo: prop['id'])
            .get();
        totalBookings += bookingsSnap.docs.length;
      }

      setState(() {
        _dashboardData = {
          'user': userDoc.data() ?? {},
          'properties': properties,
          'totalBookings': totalBookings,
          'activeProperties':
              properties.where((p) => p['status'] == 'active').length,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[FarmhouseOwnerDashboard] Error loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _dashboardData['user'] as Map<String, dynamic>?;
    final properties = _dashboardData['properties'] as List<dynamic>?;
    final totalBookings = _dashboardData['totalBookings'] as int? ?? 0;
    final activeProperties = _dashboardData['activeProperties'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmhouse Owner Dashboard'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      drawer: AppDrawerWithRoles(uid: _uid),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome section
                          Text(
                            'Welcome, ${user?['name'] ?? 'Owner'}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Stats Cards
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Properties',
                                  value: '${properties?.length ?? 0}',
                                  icon: Icons.house_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Active',
                                  value: '$activeProperties',
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Bookings',
                                  value: '$totalBookings',
                                  icon: Icons.calendar_today_outlined,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Revenue',
                                  value: '₹0',
                                  icon: Icons.money_outlined,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Properties Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Manage Properties',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Add Property - Coming Soon'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (properties == null || properties.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 32),
                                  const Icon(
                                    Icons.house_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No properties yet'),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: properties.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final prop =
                                    properties[index] as Map<String, dynamic>;
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.house),
                                    title: Text(prop['name'] ?? 'Property'),
                                    subtitle: Text(
                                      prop['location'] ?? 'Location unknown',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        prop['status'] ?? 'active',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor:
                                          prop['status'] == 'active'
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
