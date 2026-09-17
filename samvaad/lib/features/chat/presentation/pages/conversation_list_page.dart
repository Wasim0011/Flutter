import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/conversation_list_controller.dart';
import '../../../auth/presentation/controllers/onboarding_controller.dart';

class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AppUser?> authState = ref.watch(authStateChangesProvider);
    final String? userId = authState.value?.id;

    if (userId == null) {
      // Router guard should never let a signed-out user reach this
      // page, but a null-safe fallback costs nothing and avoids a
      // crash if that invariant is ever violated during development.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AsyncValue<List<Conversation>> conversations =
    ref.watch(conversationListProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Samvaad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'New group',
            onPressed: () => context.push(AppRoutes.createGroup),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.startChat),
        tooltip: 'New chat',
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Couldn\'t load conversations.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No conversations yet. Tap the chat button to start one.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // final Conversation conversation = list[index];
              // final String title = conversation.isGroup
              //     ? (conversation.title ?? 'Group')
              //     : (conversation.otherParticipantId(userId) ?? 'Unknown');
              return _ConversationTile(
                conversation: list[index],
                currentUserId: userId,
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation, required this.currentUserId});

  final Conversation conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? otherId = conversation.otherParticipantId(currentUserId);
    final String title = conversation.isGroup
        ? (conversation.title ?? 'Group')
        : _resolveDirectTitle(ref, otherId);

    return ListTile(
      leading: CircleAvatar(
        child: Icon(conversation.isGroup ? Icons.group : Icons.person),
      ),
      title: Text(title),
      subtitle: Text(
        conversation.lastMessagePreview ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        context.push(
          AppRoutes.conversation,
          extra: {'conversationId': conversation.id, 'title': title},
        );
      },
    );
  }

  /// Watches the other participant's display name, falling back to
  /// their raw user id only while the name hasn't loaded yet or was
  /// never set — the honest gap from Milestone 3.3 is now resolved in
  /// the common case, with a graceful (not silent) fallback remaining.
  String _resolveDirectTitle(WidgetRef ref, String? otherId) {
    if (otherId == null) return 'Unknown';
    final AsyncValue<String?> nameAsync = ref.watch(displayNameProvider(otherId));
    return nameAsync.value ?? otherId;
  }
}