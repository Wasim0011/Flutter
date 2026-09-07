import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

import '../../features/orders/data/models/order_chat_model.dart';
import '../../features/app_config/presentation/bloc/app_config_bloc.dart';

/// Firebase Realtime Database Chat Service
/// Handles real-time messaging for order chats
class FirebaseChatService {
  static FirebaseChatService? _instance;
  late FirebaseDatabase _database;
  bool _isInitialized = false;

  FirebaseChatService._();

  static FirebaseChatService get instance {
    _instance ??= FirebaseChatService._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      // Get database URL from app config
      String? databaseURL;
      try {
        final appConfigBloc = GetIt.instance<AppConfigBloc>();
        final appConfigState = appConfigBloc.state;
        
        if (appConfigState is AppConfigLoaded) {
          databaseURL = appConfigState.config.firebaseDatabaseUrl;
        }
      } catch (_) {
        // App config not ready — fall back to the default database URL below.
      }
      
      // If no database URL from config, Firebase will use default from google-services.json
      if (databaseURL != null && databaseURL.isNotEmpty) {
        _database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: databaseURL,
        );
      } else {
        _database = FirebaseDatabase.instance;
      }
      
      // Enable offline persistence
      _database.setPersistenceEnabled(true);
      _database.setPersistenceCacheSizeBytes(10000000); // 10MB
      
      _isInitialized = true;
    } catch (e) {
      // Firebase not configured
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Get chat reference
  DatabaseReference _getChatRef(String firebaseChatId) {
    return _database.ref('chats/order_chats/$firebaseChatId');
  }

  /// Get messages reference
  DatabaseReference _getMessagesRef(String firebaseChatId) {
    return _database.ref('chats/order_chats/$firebaseChatId/messages');
  }

  /// Send a message
  Future<void> sendMessage({
    required String firebaseChatId,
    required int senderId,
    required String senderName,
    required String message,
    String messageType = 'text',
  }) async {
    if (!_isInitialized) return;

    final messagesRef = _getMessagesRef(firebaseChatId);
    final newMessageRef = messagesRef.push();

    final messageData = {
      'id': newMessageRef.key,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'message_type': messageType,
      'timestamp': ServerValue.timestamp,
      'is_read': false,
    };

    await newMessageRef.set(messageData);

    // Update chat metadata
    await _getChatRef(firebaseChatId).update({
      'last_message': message,
      'last_message_at': ServerValue.timestamp,
      'last_sender_id': senderId,
    });
  }

  /// Listen to messages
  Stream<List<ChatMessageModel>> listenToMessages(String firebaseChatId) {
    if (!_isInitialized) {
      return Stream.value([]);
    }

    return _getMessagesRef(firebaseChatId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      
      if (event.snapshot.value == null) {
        return <ChatMessageModel>[];
      }

      final messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
      final messages = <ChatMessageModel>[];

      messagesMap.forEach((key, value) {
        try {
          final messageData = Map<String, dynamic>.from(value as Map);
          messageData['id'] = key;
          
          // Convert timestamp
          if (messageData['timestamp'] is int) {
            messageData['timestamp'] = DateTime.fromMillisecondsSinceEpoch(
              messageData['timestamp'] as int,
            ).toIso8601String();
          } else if (messageData['timestamp'] == null) {
            // Handle null timestamp
            messageData['timestamp'] = DateTime.now().toIso8601String();
          }

          messages.add(ChatMessageModel.fromJson(messageData));
        } catch (e) {
          // Skip invalid messages
        }
      });

      // Sort by timestamp (newest last)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String firebaseChatId,
    required int currentUserId,
  }) async {
    if (!_isInitialized) return;

    final messagesRef = _getMessagesRef(firebaseChatId);
    final snapshot = await messagesRef.get();

    if (snapshot.value == null) return;

    final messagesMap = snapshot.value as Map<dynamic, dynamic>;
    final updates = <String, dynamic>{};

    messagesMap.forEach((key, value) {
      final message = Map<String, dynamic>.from(value as Map);
      final senderId = message['sender_id'] as int;
      final isRead = message['is_read'] as bool? ?? false;

      // Mark as read if sent by other user and not already read
      if (senderId != currentUserId && !isRead) {
        updates['$key/is_read'] = true;
      }
    });

    if (updates.isNotEmpty) {
      await messagesRef.update(updates);
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount({
    required String firebaseChatId,
    required int currentUserId,
  }) async {
    if (!_isInitialized) return 0;

    final messagesRef = _getMessagesRef(firebaseChatId);
    final snapshot = await messagesRef.get();

    if (snapshot.value == null) return 0;

    final messagesMap = snapshot.value as Map<dynamic, dynamic>;
    int unreadCount = 0;

    messagesMap.forEach((key, value) {
      final message = Map<String, dynamic>.from(value as Map);
      final senderId = message['sender_id'] as int;
      final isRead = message['is_read'] as bool? ?? false;

      if (senderId != currentUserId && !isRead) {
        unreadCount++;
      }
    });

    return unreadCount;
  }

  /// Listen to unread count
  Stream<int> listenToUnreadCount({
    required String firebaseChatId,
    required int currentUserId,
  }) {
    if (!_isInitialized) {
      return Stream.value(0);
    }

    return _getMessagesRef(firebaseChatId).onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
      int unreadCount = 0;

      messagesMap.forEach((key, value) {
        final message = Map<String, dynamic>.from(value as Map);
        final senderId = message['sender_id'] as int;
        final isRead = message['is_read'] as bool? ?? false;

        if (senderId != currentUserId && !isRead) {
          unreadCount++;
        }
      });

      return unreadCount;
    });
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String firebaseChatId,
    required String messageId,
  }) async {
    if (!_isInitialized) return;

    await _getMessagesRef(firebaseChatId).child(messageId).remove();
  }

  /// Clear all messages
  Future<void> clearChat(String firebaseChatId) async {
    if (!_isInitialized) return;

    await _getMessagesRef(firebaseChatId).remove();
  }

  /// Check if user is typing
  Future<void> setTypingStatus({
    required String firebaseChatId,
    required int userId,
    required bool isTyping,
  }) async {
    if (!_isInitialized) return;

    await _getChatRef(firebaseChatId).child('typing').update({
      userId.toString(): isTyping ? ServerValue.timestamp : null,
    });
  }

  /// Listen to typing status
  Stream<bool> listenToTypingStatus({
    required String firebaseChatId,
    required int otherUserId,
  }) {
    if (!_isInitialized) {
      return Stream.value(false);
    }

    return _getChatRef(firebaseChatId)
        .child('typing/$otherUserId')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return false;

      final timestamp = event.snapshot.value as int;
      final typingTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Consider typing if less than 5 seconds ago
      return now.difference(typingTime).inSeconds < 5;
    });
  }

  /// Get support chat reference (separate path from order chats)
  DatabaseReference _getSupportChatRef(String firebaseChatId) {
    return _database.ref('chats/support_chats/$firebaseChatId');
  }

  /// Get support chat messages reference
  DatabaseReference _getSupportMessagesRef(String firebaseChatId) {
    return _database.ref('chats/support_chats/$firebaseChatId/messages');
  }

  /// Send a message to a support chat
  Future<void> sendSupportMessage({
    required String firebaseChatId,
    required int senderId,
    required String senderName,
    required String message,
  }) async {
    if (!_isInitialized) return;
    final messagesRef = _getSupportMessagesRef(firebaseChatId);
    final newRef = messagesRef.push();
    await newRef.set({
      'id': newRef.key,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'message_type': 'text',
      'timestamp': ServerValue.timestamp,
      'is_read': false,
    });
    await _getSupportChatRef(firebaseChatId).update({
      'last_message': message,
      'last_message_at': ServerValue.timestamp,
      'last_sender_id': senderId,
    });
  }

  /// Listen to support chat messages
  Stream<List<ChatMessageModel>> listenToSupportMessages(String firebaseChatId) {
    if (!_isInitialized) return Stream.value([]);
    return _getSupportMessagesRef(firebaseChatId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <ChatMessageModel>[];
      final messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
      final messages = <ChatMessageModel>[];
      messagesMap.forEach((key, value) {
        try {
          final messageData = Map<String, dynamic>.from(value as Map);
          messageData['id'] = key;
          if (messageData['timestamp'] is int) {
            messageData['timestamp'] = DateTime.fromMillisecondsSinceEpoch(
              messageData['timestamp'] as int,
            ).toIso8601String();
          } else if (messageData['timestamp'] == null) {
            messageData['timestamp'] = DateTime.now().toIso8601String();
          }
          messages.add(ChatMessageModel.fromJson(messageData));
        } catch (e) {
          // Non-critical: skip malformed message entries.
        }
      });
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Listen to any typing activity in a support chat (any user other than self)
  Stream<bool> listenToSupportTyping({
    required String firebaseChatId,
    required int currentUserId,
  }) {
    if (!_isInitialized) return Stream.value(false);
    return _getSupportChatRef(firebaseChatId)
        .child('typing')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return false;
      final typingMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      final now = DateTime.now();
      for (final entry in typingMap.entries) {
        if (entry.key == currentUserId.toString()) continue;
        final ts = entry.value;
        if (ts is int) {
          final typingTime = DateTime.fromMillisecondsSinceEpoch(ts);
          if (now.difference(typingTime).inSeconds < 5) return true;
        }
      }
      return false;
    });
  }

  /// Set typing status in a support chat
  Future<void> setSupportTypingStatus({
    required String firebaseChatId,
    required int userId,
    required bool isTyping,
  }) async {
    if (!_isInitialized) return;
    await _getSupportChatRef(firebaseChatId).child('typing').update({
      userId.toString(): isTyping ? ServerValue.timestamp : null,
    });
  }

  /// Dispose
  void dispose() {
    // Firebase Database doesn't need explicit disposal
  }
}
