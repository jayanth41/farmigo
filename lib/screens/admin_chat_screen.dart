import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatScreen extends StatefulWidget {
  final String? chatId;

  const AdminChatScreen({super.key, this.chatId});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _chatId => widget.chatId ?? _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _markUserMessagesAsSeen();
    _resetAdminUnreadCount();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = (doc.data() as Map<String, dynamic>?) ?? {};

                    final currentUid = _auth.currentUser?.uid;

                    final senderId = data['senderId']?.toString() ?? '';
                    final isMe = currentUid != null && senderId == currentUid;

                    final text = (data['text'] ?? '') as String;
                    final senderIdRaw = data['senderId']?.toString() ?? '';
                    final senderRoleRaw = (data['sender'] as String?)?.toLowerCase() ?? '';

                    return Align(
  alignment: isMe
      ? Alignment.centerRight
      : Alignment.centerLeft,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.75,
    ),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF1E88E5)   // Strong blue for sender
            : const Color(0xFFF1F3F6),  // Soft grey for receiver
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe
              ? const Radius.circular(16)
              : const Radius.circular(4),
          bottomRight: isMe
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
                          child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isMe ? Colors.white : Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 4),
          Text(
            _formatTime(data['timestamp']),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isMe ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  ),
);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
            )
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

  await _firestore
    .collection('chats')
    .doc(_chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': _auth.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });

    // Update parent chat document so admin sees the new message as unread.
    await _firestore.collection('chats').doc(_chatId).update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCountAdmin': FieldValue.increment(1),
    });

    _messageController.clear();
  }

  Future<void> _markUserMessagesAsSeen() async {
  try {
    final snapshot = await _firestore
      .collection('chats')
      .doc(_chatId)
          .collection('messages')
          .where('isSeen', isEqualTo: false)
          .get();

    final adminUid = _auth.currentUser?.uid;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final senderId = data['senderId']?.toString() ?? '';

      if (adminUid != null && senderId != adminUid) {
        await doc.reference.update({'isSeen': true});
      }
    }
  } catch (e) {
    // ignore
  }
  }

  Future<void> _resetAdminUnreadCount() async {
  await _firestore
    .collection('chats')
    .doc(_chatId)
    .update({'unreadCountAdmin': 0});
  }

  String _formatTime(dynamic timestamp) {
  if (timestamp == null || timestamp is! Timestamp) return '';
  final dt = timestamp.toDate();
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return "$hour:$minute";
}
}