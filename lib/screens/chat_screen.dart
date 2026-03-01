import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String propertyName;
  final String ownerName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.propertyName,
    required this.ownerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ownerName),
            Text(
              widget.propertyName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == widget.currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.blue
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: isCurrentUser ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCurrentUser
                                      ? Colors.white70
                                      : Colors.grey.shade600,
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

          // Message Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    final success = await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      senderName: 'Current User', // Replace with actual user name
      message: message,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
