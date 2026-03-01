class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class ChatModel {
  final String id;
  final String propertyId;
  final String userId;
  final String ownerId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime lastMessageTime;
  final String lastMessagePreview;

  ChatModel({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.ownerId,
    required this.participants,
    required this.createdAt,
    required this.lastMessageTime,
    required this.lastMessagePreview,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      propertyId: json['propertyId'] ?? '',
      userId: json['userId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastMessageTime: DateTime.parse(json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      lastMessagePreview: json['lastMessagePreview'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'ownerId': ownerId,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
    };
  }
}
