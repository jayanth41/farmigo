import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatScreen extends StatefulWidget {
  final String chatId;
  const AdminChatScreen({super.key, required this.chatId});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _adminUid;

  @override
  void initState() {
    super.initState();
    _adminUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('ADMIN UID: $_adminUid');
    if (_adminUid != null) {
      _markAdminMessagesAsSeen();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markAdminMessagesAsSeen() async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _adminUid)
          .where('isSeen', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isSeen': true});
      }

      await _firestore.collection('chats').doc(widget.chatId).set({
        'unreadCountUser': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final messagesRef = _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    await messagesRef.add({
      'text': text,
      'senderId': _adminUid ?? 'admin',
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });

    await _firestore.collection('chats').doc(widget.chatId).set({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCountUser': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Chat: ${widget.chatId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet'),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = (doc.data() as Map<String, dynamic>?) ?? {};
                    final senderId = data['senderId'] ?? data['sender'] ?? '';
                    
                    // Temporary debug log
                    debugPrint('Message senderId: $senderId | AdminUid: $_adminUid');

                    // Fix: also handle literal "admin" sender case
                    final isAdmin = senderId == (_adminUid ?? 'admin');

                    return Align(
                      alignment:
                          isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? const Color.fromARGB(255, 41, 70, 92)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isAdmin
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                            bottomRight: isAdmin
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data['text'] ?? '') as String,
                              style: TextStyle(
                                color: isAdmin ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  data['isSeen'] == true
                                      ? Icons.done_all
                                      : Icons.done,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Color.fromARGB(255, 41, 70, 92),
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
