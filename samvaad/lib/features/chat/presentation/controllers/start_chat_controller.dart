import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/presentation/controllers/onboarding_controller.dart';
import '../../domain/entities/conversation.dart';
import '../providers/chat_providers.dart';

part 'start_chat_controller.g.dart';

sealed class StartChatState {
  const StartChatState();
}

final class StartChatIdle extends StartChatState {
  const StartChatIdle();
}

final class StartChatSearching extends StartChatState {
  const StartChatSearching();
}

final class StartChatFailed extends StartChatState {
  const StartChatFailed(this.message);
  final String message;
}

final class StartChatReady extends StartChatState {
  const StartChatReady(this.conversation);
  final Conversation conversation;
}

@riverpod
class StartChatController extends _$StartChatController {
  @override
  StartChatState build() => const StartChatIdle();

  Future<void> startChatWithPhoneNumber({
    required String currentUserId,
    required String phoneNumber,
  }) async {
    state = const StartChatSearching();

    final lookup = await ref.read(userProfileRepositoryProvider).findUserIdByPhoneNumber(phoneNumber);

    final String? otherUserId = lookup.fold(
      onSuccess: (id) => id,
      onFailure: (_) => null,
    );

    if (otherUserId == null) {
      state = const StartChatFailed('No Samvaad user found with that phone number.');
      return;
    }
    if (otherUserId == currentUserId) {
      state = const StartChatFailed('That\'s your own number.');
      return;
    }

    final result = await ref.read(chatRepositoryProvider).createOrGetDirectConversation(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );

    state = result.fold(
      onSuccess: (conversation) => StartChatReady(conversation),
      onFailure: (failure) => StartChatFailed(_messageFor(failure)),
    );
  }

  void reset() => state = const StartChatIdle();

  String _messageFor(Failure failure) => failure.message;
}