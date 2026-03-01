import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or get existing chat between user and owner
  Future<ChatModel?> getOrCreateChat({
    required String propertyId,
    required String userId,
    required String ownerId,
  }) async {
    try {
      // Check if chat already exists
      final existing = await _firestore
          .collection('chats')
          .where('propertyId', isEqualTo: propertyId)
          .where('participants', arrayContains: userId)
          .get();
      
      for (var doc in existing.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(ownerId)) {
          return ChatModel.fromJson({...data, 'id': doc.id});
        }
      }
      
      // Create new chat
      final newChatRef = await _firestore.collection('chats').add({
        'propertyId': propertyId,
        'userId': userId,
        'ownerId': ownerId,
        'participants': [userId, ownerId],
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessagePreview': '',
      });
      
      return ChatModel.fromJson({
        'id': newChatRef.id,
        'propertyId': propertyId,
        'userId': userId,
        'ownerId': ownerId,
        'participants': [userId, ownerId],
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessagePreview': '',
      });
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      return null;
    }
  }

  /// Get all messages in a chat
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Send a message
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages');
      
      await messageRef.add({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });
      
      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessagePreview': message,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
