import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/message.dart';
import '../providers/chat_providers.dart';

part 'message_thread_controller.g.dart';

/// Live stream of messages for one conversation.
@riverpod
Stream<List<Message>> messageThread(Ref ref, String conversationId) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
}

sealed class SendMessageState {
  const SendMessageState();
}

final class SendMessageIdle extends SendMessageState {
  const SendMessageIdle();
}

final class SendMessageSending extends SendMessageState {
  const SendMessageSending();
}

final class SendMessageFailed extends SendMessageState {
  const SendMessageFailed(this.message);
  final String message;
}

@riverpod
class SendMessageController extends _$SendMessageController {
  @override
  SendMessageState build() => const SendMessageIdle();

  Future<void> send({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    state = const SendMessageSending();

    final result = await ref.read(chatRepositoryProvider).sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      text: text.trim(),
    );

    state = result.fold(
      onSuccess: (_) => const SendMessageIdle(),
      onFailure: (failure) => SendMessageFailed(failure.message),
    );
  }
}