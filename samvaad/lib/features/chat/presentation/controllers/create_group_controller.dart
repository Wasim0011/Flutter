import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/controllers/onboarding_controller.dart';
import '../../domain/entities/conversation.dart';
import '../providers/chat_providers.dart';

part 'create_group_controller.g.dart';

sealed class CreateGroupState {
  const CreateGroupState();
}

final class CreateGroupIdle extends CreateGroupState {
  const CreateGroupIdle();
}

final class CreateGroupSubmitting extends CreateGroupState {
  const CreateGroupSubmitting();
}

final class CreateGroupFailed extends CreateGroupState {
  const CreateGroupFailed(this.message);
  final String message;
}

final class CreateGroupReady extends CreateGroupState {
  const CreateGroupReady(this.conversation);
  final Conversation conversation;
}

@riverpod
class CreateGroupController extends _$CreateGroupController {
  @override
  CreateGroupState build() => const CreateGroupIdle();

  /// Takes phone numbers (what the UI collects) and resolves each to a
  /// user id before creating the group — mirroring the same lookup
  /// StartChatController does for 1:1 chats, so both flows agree on
  /// "you add people by phone number" as the one way to find someone.
  Future<void> create({
    required String currentUserId,
    required List<String> participantPhoneNumbers,
    required String title,
  }) async {
    if (participantPhoneNumbers.isEmpty) {
      state = const CreateGroupFailed('Add at least one other participant.');
      return;
    }
    if (title.trim().isEmpty) {
      state = const CreateGroupFailed('Give the group a name.');
      return;
    }

    state = const CreateGroupSubmitting();

    final List<String> resolvedIds = [];
    for (final phone in participantPhoneNumbers) {
      final lookup = await ref.read(userProfileRepositoryProvider).findUserIdByPhoneNumber(phone);
      final String? id = lookup.fold(onSuccess: (id) => id, onFailure: (_) => null);
      if (id == null) {
        state = CreateGroupFailed('No Samvaad user found for $phone.');
        return;
      }
      resolvedIds.add(id);
    }

    final result = await ref.read(chatRepositoryProvider).createGroupConversation(
      currentUserId: currentUserId,
      participantIds: resolvedIds,
      title: title.trim(),
    );

    state = result.fold(
      onSuccess: (conversation) => CreateGroupReady(conversation),
      onFailure: (failure) => CreateGroupFailed(failure.message),
    );
  }
}