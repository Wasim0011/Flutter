import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/conversation_list_controller.dart';

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
              final Conversation conversation = list[index];
              final String title = conversation.isGroup
                  ? (conversation.title ?? 'Group')
                  : (conversation.otherParticipantId(userId) ?? 'Unknown');
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
                  // Conversation screen itself is Milestone 3.4 — for
                  // now this is a no-op tap target, intentionally,
                  // rather than a half-built navigation to a screen
                  // that doesn't exist yet.
                },
              );
            },
          );
        },
      ),
    );
  }
}