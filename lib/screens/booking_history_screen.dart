import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

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
        bg = Colors.grey.shade100;
        text = Colors.grey.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final d = ts.toDate();
        return '${d.day}/${d.month}/${d.year}';
      }
      if (ts is DateTime) {
        final d = ts;
        return '${d.day}/${d.month}/${d.year}';
      }
      if (ts is String) {
        // try parse
        final p = DateTime.tryParse(ts);
        if (p != null) return '${p.day}/${p.month}/${p.year}';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      drawer: const AppDrawer(),
      body: uid == null
          ? const Center(child: Text('Please log in to view booking history'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Failed to load bookings', style: TextStyle(color: Colors.red.shade700)));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text('No bookings yet.', style: TextStyle(color: Colors.grey.shade700)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data();
                    final listingId = data['listingId'] as String? ?? 'Listing';
                    final guests = data['guests']?.toString() ?? '-';
                    final totalAmount = data['totalAmount'] != null ? '₹ ${data['totalAmount'].toString()}' : '₹ 0';
                    final status = (data['status'] as String?) ?? 'unknown';
                    final checkIn = _formatDate(data['checkIn']);
                    final checkOut = _formatDate(data['checkOut']);

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(listingId, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text('$checkIn → $checkOut', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                                  const SizedBox(height: 6),
                                  Text('$guests guests', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                                  const SizedBox(height: 8),
                                  _buildStatusBadge(status),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(totalAmount, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
