import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_chat_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // When opening the notification screen, mark unreadCountUser = 0 for relevant chats
    WidgetsBinding.instance.addPostFrameCallback((_) => _clearUnreadCounts());
  }

  Future<void> _clearUnreadCounts() async {
    if (_uid == null) return;
    try {
      final query = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: _uid)
          .where('unreadCountUser', isGreaterThan: 0)
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'unreadCountUser': 0});
      }
      if (query.docs.isNotEmpty) await batch.commit();
    } catch (e) {
      // ignore errors for now
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please login to see notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('userId', isEqualTo: _uid)
            .where('unreadCountUser', isGreaterThan: 0)
            .orderBy('unreadCountUser')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = docs[index];
              final data = chat.data() as Map<String, dynamic>? ?? {};
              final lastMessage = data['lastMessage'] ?? '';
              final unread = data['unreadCountUser'] ?? 0;
              final timestamp = data['updatedAt'];
              String timeText = '';
              if (timestamp != null && timestamp is Timestamp) {
                final dt = timestamp.toDate();
                timeText = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }

              return ListTile(
                title: Text(lastMessage.toString()),
                subtitle: Text(timeText),
                trailing: null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminChatScreen(
                        chatId: chat.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
