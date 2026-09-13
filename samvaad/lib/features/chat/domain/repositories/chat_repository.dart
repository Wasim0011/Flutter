import '../../../../core/error/result.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

/// Contract for chat persistence and real-time delivery, implemented
/// against Firestore in Milestone 3.2.
///
/// Two streaming methods (`watchConversations`, `watchMessages`)
/// reflect the decision that chat should feel live — Firestore
/// snapshot listeners underneath, but that's an implementation detail
/// this interface doesn't expose.
abstract interface class ChatRepository {
  /// Live list of conversations [userId] participates in, ordered by
  /// most recent activity first.
  Stream<List<Conversation>> watchConversations(String userId);

  /// Live list of messages in [conversationId], ordered oldest first.
  Stream<List<Message>> watchMessages(String conversationId);

  /// Creates a new direct (1:1) conversation between [currentUserId]
  /// and [otherUserId], or returns the existing one if a direct
  /// conversation between these two users already exists — callers
  /// should not need to check for duplicates themselves.
  Future<Result<Conversation>> createOrGetDirectConversation({
    required String currentUserId,
    required String otherUserId,
  });

  /// Creates a new named group conversation with [participantIds]
  /// (which should include [currentUserId]).
  Future<Result<Conversation>> createGroupConversation({
    required String currentUserId,
    required List<String> participantIds,
    required String title,
  });

  /// Sends a text message into [conversationId].
  Future<Result<void>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
}