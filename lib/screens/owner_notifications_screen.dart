import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerNotificationsScreen extends StatelessWidget {
  const OwnerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please sign in to see notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No notifications'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>? ?? {};
              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? '';
              final isRead = data['isRead'] == true;
              final createdAt = data['createdAt'];

              return Material(
                color: isRead ? Colors.white : const Color(0xFFF1F8FF),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    // Mark as read when opened
                    try {
                      await FirebaseFirestore.instance.collection('notifications').doc(d.id).update({'isRead': true});
                    } catch (_) {}
                    // Optionally show details
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(title),
                        content: Text(message),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isRead ? Colors.grey[200] : Colors.blue[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications, color: isRead ? Colors.black54 : Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(message, style: const TextStyle(color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Column(children: [
                        Text(_formatTimestamp(createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 6),
                        if (!isRead)
                          TextButton(
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance.collection('notifications').doc(d.id).update({'isRead': true});
                              } catch (_) {}
                            },
                            child: const Text('Mark read'),
                          ),
                      ])
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      if (ts is Timestamp) {
        final dt = ts.toDate();
        return _shortTime(dt);
      }
      if (ts is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        return _shortTime(dt);
      }
      if (ts is DateTime) return _shortTime(ts);
    } catch (_) {}
    return '';
  }

  static String _shortTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
