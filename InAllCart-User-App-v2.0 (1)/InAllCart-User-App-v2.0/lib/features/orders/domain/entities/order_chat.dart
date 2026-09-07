import 'package:equatable/equatable.dart';

class OrderChat extends Equatable {
  final int chatId;
  final String firebaseChatId;
  final String chatType; // 'customer_delivery' or 'customer_seller'
  final int orderId;
  final ChatParticipant customer;
  final ChatParticipant? participant;
  final bool isActive;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const OrderChat({
    required this.chatId,
    required this.firebaseChatId,
    required this.chatType,
    required this.orderId,
    required this.customer,
    this.participant,
    required this.isActive,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  bool get isDeliveryChat => chatType == 'customer_delivery';
  bool get isSellerChat => chatType == 'customer_seller';

  String get chatTitle {
    if (isDeliveryChat) return 'Delivery Partner';
    if (isSellerChat) return 'Seller';
    return 'Chat';
  }

  @override
  List<Object?> get props => [
        chatId,
        firebaseChatId,
        chatType,
        orderId,
        customer,
        participant,
        isActive,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}

class ChatParticipant extends Equatable {
  final int id;
  final String name;
  final String? avatar;
  final String? phone;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, avatar, phone];
}

class ChatMessage extends Equatable {
  final String id;
  final int senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String messageType; // 'text', 'image', 'location'

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        message,
        timestamp,
        isRead,
        messageType,
      ];
}
