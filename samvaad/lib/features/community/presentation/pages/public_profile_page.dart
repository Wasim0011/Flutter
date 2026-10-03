import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../domain/entities/public_profile.dart';
import '../controllers/directory_controller.dart';

class PublicProfilePage extends ConsumerStatefulWidget {
  const PublicProfilePage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> {
  bool _startingChat = false;

  Future<void> _message(String currentUserId) async {
    setState(() => _startingChat = true);
    final result = await ref
        .read(chatRepositoryProvider)
        .createOrGetDirectConversation(
          currentUserId: currentUserId,
          otherUserId: widget.userId,
        );

    if (!mounted) return;
    setState(() => _startingChat = false);

    result.fold(
      onSuccess: (conversation) {
        // Read the already-resolved profile here rather than relying on
        // build()'s local variable, which isn't in scope in this method.
        final String title =
            ref.read(publicProfileProvider(widget.userId)).value?.displayName ??
            'Chat';
        context.pushReplacement(
          AppRoutes.conversation,
          extra: {'conversationId': conversation.id, 'title': title},
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t start chat: ${failure.message}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<PublicProfile?> profileAsync = ref.watch(
      publicProfileProvider(widget.userId),
    );
    final String? currentUserId = ref.watch(authStateChangesProvider).value?.id;
    final bool isSelf = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Couldn\'t load this profile.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'This person hasn\'t set up their profile yet.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    child: Text(
                      profile.initials,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio ?? 'No bio yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!isSelf)
                    Semantics(
                      button: true,
                      label: 'Message ${profile.displayName}',
                      child: ElevatedButton.icon(
                        onPressed: (_startingChat || currentUserId == null)
                            ? null
                            : () => _message(currentUserId),
                        icon: _startingChat
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
