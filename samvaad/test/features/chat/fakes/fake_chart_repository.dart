import 'dart:async';
import 'package:samvaad/core/error/result.dart';
import 'package:samvaad/features/chat/domain/entities/conversation.dart';
import 'package:samvaad/features/chat/domain/entities/message.dart';
import 'package:samvaad/features/chat/domain/repositories/chat_repository.dart';

class FakeChatRepository implements ChatRepository {
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<Message>> _messages = {};
  int _idCounter = 0;

  final StreamController<List<Conversation>> _conversationsController =
  StreamController.broadcast();
  final Map<String, StreamController<List<Message>>> _messageControllers = {};

  String _nextId() => 'fake-id-${_idCounter++}';

  void _emitConversations() => _conversationsController.add(_conversations.values.toList());

  void _emitMessages(String conversationId) {
    _messageControllers[conversationId]?.add(_messages[conversationId] ?? []);
  }

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return Stream<List<Conversation>>.multi((controller) {
      controller.add(
        _conversations.values.where((c) => c.participantIds.contains(userId)).toList(),
      );
      final sub = _conversationsController.stream.listen(
            (all) => controller.add(all.where((c) => c.participantIds.contains(userId)).toList()),
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    // ignore: close_sinks
    // False positive: this controller is stored in _messageControllers
    // and closed in dispose() — the lint can't trace across the
    // putIfAbsent callback boundary to see that.
    final controller = _messageControllers.putIfAbsent(
      conversationId,
          () => StreamController<List<Message>>.broadcast(),
    );
    return Stream<List<Message>>.multi((multiController) {
      multiController.add(_messages[conversationId] ?? []);
      final sub = controller.stream.listen(multiController.add);
      multiController.onCancel = sub.cancel;
    });
  }

  @override
  Future<Result<Conversation>> createOrGetDirectConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final existing = _conversations.values.where(
          (c) =>
      !c.isGroup &&
          c.participantIds.contains(currentUserId) &&
          c.participantIds.contains(otherUserId),
    ).firstOrNull;
    if (existing != null) return Result.success(existing);

    final conversation = Conversation(
      id: _nextId(),
      type: ConversationType.direct,
      participantIds: [currentUserId, otherUserId],
      createdAt: DateTime.now(),
    );
    _conversations[conversation.id] = conversation;
    _emitConversations();
    return Result.success(conversation);
  }

  @override
  Future<Result<Conversation>> createGroupConversation({
    required String currentUserId,
    required List<String> participantIds,
    required String title,
  }) async {
    final conversation = Conversation(
      id: _nextId(),
      type: ConversationType.group,
      participantIds: {currentUserId, ...participantIds}.toList(),
      createdAt: DateTime.now(),
      title: title,
    );
    _conversations[conversation.id] = conversation;
    _emitConversations();
    return Result.success(conversation);
  }

  @override
  Future<Result<void>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final message = Message(
      id: _nextId(),
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      sentAt: DateTime.now(),
    );
    _messages.putIfAbsent(conversationId, () => []).add(message);
    _emitMessages(conversationId);

    final existing = _conversations[conversationId];
    if (existing != null) {
      _conversations[conversationId] = Conversation(
        id: existing.id,
        type: existing.type,
        participantIds: existing.participantIds,
        createdAt: existing.createdAt,
        title: existing.title,
        lastMessagePreview: text,
        lastMessageAt: message.sentAt,
      );
      _emitConversations();
    }

    return const Result.success(null);
  }

  void dispose() {
    _conversationsController.close();
    for (final c in _messageControllers.values) {
      c.close();
    }
  }
}