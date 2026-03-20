import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    _listenForMessageNotifications();
  }

  void _listenForMessageNotifications() async {
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();

    // FirebaseMessaging.onMessage.listen((dynamic message) {
    //   if (message.data['type'] == 'new_message') {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('New message received')),
    //     );
    //     setState(() {});
    //   }
    // });
  }
  int _tabIndex = 0; // 0 = Active, 1 = Archived
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 10,
            16,
            16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Chat with your guests and manage inquiries',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color.fromARGB(255, 41, 70, 92),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 41, 70, 92)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {},
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF29465C).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0
                                ? const Color.fromARGB(255, 41, 70, 92)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _tabIndex == 0 ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1
                                ? const Color.fromARGB(255, 41, 70, 92)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Archived',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _tabIndex == 1 ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _tabIndex == 0
                  ? StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('conversations')
                          .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('archived', isEqualTo: false)
                          .orderBy('updatedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No active conversations'));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ConversationTile(
                      name: data['guestName'] ?? 'Guest',
                      conversationId: doc.id,
                      subtitle: '${data['propertyName'] ?? ''}\n${data['lastMessage'] ?? ''}',
                      time: data['lastSeenText'] ?? '',
                      avatarUrl: '',
                      activeTag: data['activeBooking'] == true,
                      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
                    ),
                  );
                          },
                        );
                      },
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('conversations')
                          .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('archived', isEqualTo: true)
                          .orderBy('updatedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No archived conversations'));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ConversationTile(
                      name: data['guestName'] ?? 'Guest',
                      conversationId: doc.id,
                      subtitle: data['propertyName'] ?? '',
                      time: data['lastSeenText'] ?? '',
                      avatarUrl: '',
                      activeTag: false,
                      unreadCount: 0,
                    ),
                  );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String conversationId;
  final String subtitle;
  final String time;
  final String avatarUrl;
  final bool activeTag;
  final int unreadCount;

  const _ConversationTile({
    required this.name,
    required this.conversationId,
    required this.subtitle,
    required this.time,
    required this.avatarUrl,
    this.activeTag = false,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              contactName: name,
              conversationId: conversationId,
            ),
          ),
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE3F2FD),
                child: const Icon(Icons.person_outline, color: Color.fromARGB(255, 41, 70, 92)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:const Color.fromARGB(255, 41, 70, 92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (activeTag)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Active Booking', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String conversationId;
  const ChatScreen({super.key, required this.contactName, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenForMessageNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archive conversation',
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .update({'archived': true});
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .doc(widget.conversationId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final d = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final photo = (d['propertyPhoto'] as String?) ?? '';
              final start = d['checkIn'] ?? '';
              final end = d['checkOut'] ?? '';
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: photo.isEmpty
                          ? Container(width: 64, height: 64, color: Colors.grey[200], child: const Icon(Icons.home))
                          : Image.network(photo, width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['propertyName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Check-in: $start', style: const TextStyle(fontSize: 12)),
                          Text('Check-out: $end', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data() as Map<String, dynamic>;
                    final isOwner = m['from'] == 'owner';
                    return Align(
                      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
                      child: Chip(label: Text(m['text'] ?? '')),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 41, 70, 92)),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(widget.conversationId)
                        .collection('messages')
                        .add({
                      'text': text,
                      'from': 'owner',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    await FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(widget.conversationId)
                        .update({
                      'lastMessage': text,
                      'updatedAt': FieldValue.serverTimestamp(),
                      'unreadCount': 0,
                    });
                    _controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _listenForMessageNotifications() {
    // Placeholder for FCM: when a new message arrives for this conversation,
    // increment unreadCount in Firestore and trigger a local notification.
    // This will be wired to FirebaseMessaging later.
  }
}
