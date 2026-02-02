import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'owner/add_property_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  // Small helpers for demo placeholders. These should be replaced/wired
  // to real controllers/data when available; right now they are UI-only.
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (color ?? colorScheme.primary).withOpacity(0.15),
                  (color ?? colorScheme.primary).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.98),
            colorScheme.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Owner Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(fullscreenDialog: true, builder: (_) => const AddPropertyScreen()),
              );
              if (result == true) {
                debugPrint('New property added — refresh dashboard here');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Property'),
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        break;
      case 'pending':
        bg = Colors.yellow.shade100;
        text = Colors.orange.shade700;
        break;
      case 'completed':
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecentBookingCard(BuildContext context,
      {required String property,
      required String guest,
      required String dateRange,
      required String status,
      required String amount}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 6),
                    Text('$guest • $dateRange',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            )),
                    const SizedBox(height: 8),
                    _buildStatusBadge(status),
                  ]),
            ),
            const SizedBox(width: 12),
            // Price aligned vertically center
            Text(
              amount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyPerformanceRow(BuildContext context,
      {required String property,
      required int bookings,
      required int views,
      required double rating,
      required String monthlyRevenue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('$bookings bookings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    Text('$views views',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            monthlyRevenue,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700),
          )
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        // UI-only quick action; keep navigation/logic unchanged.
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.green.shade50,
              child: Icon(icon, color: Colors.green, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive layout decisions:
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final isTablet = width > 700;
    final padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

    // Placeholder demo values; wire to controllers/data as needed.
    const revenue = '₹ 1,24,560';
    const bookings = '12';
    const properties = '4';
    const rating = '4.7';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 16),

              // Stats grid
              LayoutBuilder(builder: (context, constraints) {
                final crossAxisCount = isTablet ? 4 : 2;
                final itemWidth = (constraints.maxWidth - (16 * (crossAxisCount - 1))) / crossAxisCount;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 120,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: itemWidth / 120,
                  ),
                  children: [
                    _buildStatCard(
                context: context, icon: Icons.receipt_long, value: revenue, label: 'Total Revenue', color: Colors.green),
                    _buildStatCard(
                context: context, icon: Icons.event_available, value: bookings, label: 'Active Bookings', color: Colors.green),
                    _buildStatCard(
                context: context, icon: Icons.house_siding, value: properties, label: 'Properties', color: Colors.green),
                    _buildStatCard(
                context: context, icon: Icons.star, value: rating, label: 'Avg Rating', color: Colors.amber),
                  ],
                );
              }),

              const SizedBox(height: 18),

              // Main content scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Quick actions
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Quick Actions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.grey.shade900)),
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: isTablet ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isTablet ? 1.6 : 1.1,
                        children: [
                          _buildQuickAction(
                            context,
                            icon: Icons.add_home,
                            label: 'Add Property',
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(fullscreenDialog: true, builder: (_) => const AddPropertyScreen()),
                              );
                              if (result == true) {
                                debugPrint('New property added — refresh dashboard here');
                              }
                            },
                          ),
                          _buildQuickAction(context, icon: Icons.book_online, label: 'Manage Bookings'),
                          _buildQuickAction(context, icon: Icons.analytics_outlined, label: 'View Analytics'),
                          _buildQuickAction(context, icon: Icons.settings_outlined, label: 'Property Settings'),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Recent Bookings
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Recent Bookings',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.grey.shade900)),
                        ),
                      ),
                      // Real bookings list for the owner
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                              child: Text('Failed to load bookings', style: TextStyle(color: Colors.red.shade700)),
                            );
                          }

                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final docs = snap.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(child: Text('No bookings yet.', style: TextStyle(color: Colors.grey.shade700))),
                            );
                          }

                          return Column(
                            children: docs.map((d) {
                              final data = d.data();
                              final property = (data['propertyName'] as String?)?.isNotEmpty == true
                                  ? data['propertyName'] as String
                                  : (data['listingId'] as String?) ?? 'Property';
                              final guests = (data['guests'] != null) ? data['guests'].toString() : '1';

                              String dateRange = '';
                              try {
                                final ci = data['checkIn'];
                                final co = data['checkOut'];
                                String ciStr = '';
                                String coStr = '';
                                if (ci is Timestamp) ciStr = '${ci.toDate().day}/${ci.toDate().month}/${ci.toDate().year}';
                                if (co is Timestamp) coStr = '${co.toDate().day}/${co.toDate().month}/${co.toDate().year}';
                                if (ciStr.isNotEmpty && coStr.isNotEmpty) dateRange = '$ciStr → $coStr';
                                else if (ciStr.isNotEmpty) dateRange = ciStr;
                              } catch (_) {
                                dateRange = '';
                              }

                              final status = (data['status'] as String?) ?? 'unknown';
                              final amountRaw = data['totalAmount'];
                              final amount = amountRaw != null ? '₹ ${amountRaw.toString()}' : '₹ 0';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildRecentBookingCard(
                                  context,
                                  property: property,
                                  guest: '$guests guests',
                                  dateRange: dateRange,
                                  status: status,
                                  amount: amount,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Properties Performance
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Properties Performance',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.grey.shade900)),
                        ),
                      ),

                      Column(
                        children: [
                          _buildPropertyPerformanceRow(context,
                              property: 'Lakeview Villa', bookings: 12, views: 1200, rating: 4.8, monthlyRevenue: '₹ 42,000'),
                          _buildPropertyPerformanceRow(context,
                              property: 'Green Fields Cottage', bookings: 6, views: 520, rating: 4.5, monthlyRevenue: '₹ 18,200'),
                          _buildPropertyPerformanceRow(context,
                              property: 'Hilltop Retreat', bookings: 9, views: 890, rating: 4.9, monthlyRevenue: '₹ 31,400'),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
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
