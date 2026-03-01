import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_chat_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Chats")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search chats...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aPinned = (a.data() as Map<String, dynamic>)['isPinned'] ?? false;
                    final bPinned = (b.data() as Map<String, dynamic>)['isPinned'] ?? false;
                    if (aPinned == bPinned) return 0;
                    return aPinned ? -1 : 1;
                  });

                if (chats.isEmpty) {
                  return const Center(child: Text("No chats yet"));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chatDoc = chats[index];
                    final data = chatDoc.data() as Map<String, dynamic>;

                    final unread = data['unreadCountAdmin'] ?? 0;
                    final userId = data['userId'] ?? 'Unknown User';
                    final lastMessage = data['lastMessage'] ?? '';
                    final isPinned = data['isPinned'] ?? false;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String displayName = userId;

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          displayName = userData['name'] ??
                              userData['username'] ??
                              userId;
                        }

                        // Filter chats based on search
                        if (_searchQuery.isNotEmpty &&
                            !displayName.toLowerCase().contains(_searchQuery)) {
                          return const SizedBox();
                        }

                        final photoUrl = userSnapshot.hasData && userSnapshot.data!.exists
                            ? (userSnapshot.data!.data() as Map<String, dynamic>)['photoUrl']
                            : null;

                        final isOnline = data['userOnline'] ?? false;

                        final timestamp = data['updatedAt'];
                        String timeText = '';

                        if (timestamp != null && timestamp is Timestamp) {
                          final dt = timestamp.toDate();
                          timeText =
                              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                        }

                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade300,
                                child: ClipOval(
                                  child: photoUrl != null
                                      ? Image.network(
                                          photoUrl,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                displayName.isNotEmpty
                                                    ? displayName[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    height: 12,
                                    width: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOnline ? "Online" : lastMessage,
                                style: TextStyle(
                                  color: isOnline ? Colors.green : Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPinned)
                                    const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  if (timeText.isNotEmpty)
                                    Text(
                                      timeText,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                              if (unread > 0)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.0),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          unread.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          onLongPress: () async {
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatDoc.id)
                                .update({
                              'isPinned': !isPinned,
                            });
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminChatScreen(
                                  chatId: chatDoc.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}