import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../domain/entities/community_group.dart';
import '../controllers/groups_controller.dart';
import '../providers/community_providers.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  const GroupDetailPage({required this.group, super.key});

  final CommunityGroup group;

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  bool _busy = false;

  Future<void> _toggleMembership(CommunityGroup group, String userId) async {
    setState(() => _busy = true);
    final repo = ref.read(communityRepositoryProvider);
    if (group.isMember(userId)) {
      await repo.leaveGroup(groupId: group.id, userId: userId);
    } else {
      await repo.joinGroup(groupId: group.id, userId: userId);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _startGroupChat(CommunityGroup group, String userId) async {
    setState(() => _busy = true);
    final otherMemberIds = group.memberIds.where((id) => id != userId).toList();
    final result = await ref.read(chatRepositoryProvider).createGroupConversation(
      currentUserId: userId,
      participantIds: otherMemberIds,
      title: group.name,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      onSuccess: (conversation) {
        context.pushReplacement(
          AppRoutes.conversation,
          extra: {'conversationId': conversation.id, 'title': group.name},
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t start group chat: ${failure.message}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? userId = ref.watch(authStateChangesProvider).value?.id;

    // Prefer the freshest copy from the live groups stream (reflects
    // join/leave immediately); fall back to the passed-in snapshot if
    // this group isn't in the stream's current emission yet (e.g.
    // right after creation, before the first snapshot arrives).
    final List<CommunityGroup> liveGroups = ref.watch(groupsProvider).value ?? [];
    final CommunityGroup group =
        liveGroups.where((g) => g.id == widget.group.id).firstOrNull ?? widget.group;

    final bool isMember = userId != null && group.isMember(userId);

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                group.description.isEmpty ? 'No description.' : group.description,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: (_busy || userId == null) ? null : () => _toggleMembership(group, userId),
                child: Text(isMember ? 'Leave group' : 'Join group'),
              ),
              const SizedBox(height: 12),
              if (isMember)
                ElevatedButton.icon(
                  onPressed: (_busy) ? null : () => _startGroupChat(group, userId),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Start group chat'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}