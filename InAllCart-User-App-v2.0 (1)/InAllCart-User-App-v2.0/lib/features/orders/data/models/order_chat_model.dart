import '../../domain/entities/order_chat.dart';

class OrderChatModel extends OrderChat {
  const OrderChatModel({
    required super.chatId,
    required super.firebaseChatId,
    required super.chatType,
    required super.orderId,
    required super.customer,
    super.participant,
    required super.isActive,
    super.lastMessage,
    super.lastMessageAt,
    required super.unreadCount,
  });

  factory OrderChatModel.fromJson(Map<String, dynamic> json) {
    return OrderChatModel(
      chatId: json['chat_id'] as int,
      firebaseChatId: json['firebase_chat_id'] as String,
      chatType: json['chat_type'] as String,
      orderId: json['order_id'] as int,
      customer: ChatParticipantModel.fromJson(json['customer']),
      participant: json['participant'] != null
          ? ChatParticipantModel.fromJson(json['participant'])
          : null,
      isActive: json['is_active'] as bool,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'firebase_chat_id': firebaseChatId,
      'chat_type': chatType,
      'order_id': orderId,
      'customer': (customer as ChatParticipantModel).toJson(),
      'participant': participant != null
          ? (participant as ChatParticipantModel).toJson()
          : null,
      'is_active': isActive,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}

class ChatParticipantModel extends ChatParticipant {
  const ChatParticipantModel({
    required super.id,
    required super.name,
    super.avatar,
    super.phone,
  });

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'phone': phone,
    };
  }
}

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.message,
    required super.timestamp,
    super.isRead,
    super.messageType,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] as bool? ?? false,
      messageType: json['message_type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'message_type': messageType,
    };
  }
}
