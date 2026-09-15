import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/conversation.dart';
import '../providers/chat_providers.dart';

part 'conversation_list_controller.g.dart';

/// Live stream of the current user's conversations. A StreamProvider
/// family keyed by userId — Riverpod handles subscription lifecycle
/// (cancels the Firestore listener automatically once nothing watches
/// this anymore).
@riverpod
Stream<List<Conversation>> conversationList(Ref ref, String userId) {
  return ref.watch(chatRepositoryProvider).watchConversations(userId);
}