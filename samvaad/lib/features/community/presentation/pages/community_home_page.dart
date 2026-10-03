import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/community_group.dart';
import '../../domain/entities/public_profile.dart';
import '../controllers/directory_controller.dart';
import '../controllers/groups_controller.dart';

/// Community section: a Directory of all users and a list of public
/// Groups, in tabs. Reached from the chat home screen's AppBar.
class CommunityHomePage extends StatelessWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Edit my profile',
              onPressed: () => context.push(AppRoutes.editProfile),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Directory'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        body: const TabBarView(children: [_DirectoryTab(), _GroupsTab()]),
      ),
    );
  }
}

class _DirectoryTab extends ConsumerWidget {
  const _DirectoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<PublicProfile>> directoryAsync = ref.watch(
      directoryProvider,
    );
    final String? currentUserId = ref.watch(authStateChangesProvider).value?.id;

    return directoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Couldn\'t load the directory.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
      data: (profiles) {
        final List<PublicProfile> others = profiles
            .where((p) => p.userId != currentUserId)
            .toList();
        if (others.isEmpty) {
          return Center(
            child: Text(
              'No one else has joined yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: others.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final PublicProfile profile = others[index];
            return ListTile(
              leading: CircleAvatar(child: Text(profile.initials)),
              title: Text(profile.displayName),
              subtitle: profile.bio != null
                  ? Text(
                      profile.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () =>
                  context.push(AppRoutes.publicProfile, extra: profile.userId),
            );
          },
        );
      },
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<CommunityGroup>> groupsAsync = ref.watch(
      groupsProvider,
    );
    final String? currentUserId = ref.watch(authStateChangesProvider).value?.id;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create group',
        onPressed: currentUserId == null
            ? null
            : () => _showCreateGroupSheet(context, currentUserId),
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Couldn\'t load groups.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Text(
                'No groups yet. Tap + to create one.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final CommunityGroup group = groups[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(group.name),
                subtitle: Text(
                  '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                ),
                onTap: () => context.push(AppRoutes.groupDetail, extra: group),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context, String currentUserId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateGroupSheet(currentUserId: currentUserId),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet({required this.currentUserId});

  final String currentUserId;

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CreateCommunityGroupState state = ref.watch(
      createCommunityGroupControllerProvider,
    );
    final bool isSubmitting = state is CreateCommunityGroupSubmitting;

    ref.listen<CreateCommunityGroupState>(
      createCommunityGroupControllerProvider,
      (previous, next) {
        if (next is CreateCommunityGroupReady && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New group', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Group name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
          const SizedBox(height: 16),
          if (state is CreateCommunityGroupFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () => ref
                      .read(createCommunityGroupControllerProvider.notifier)
                      .create(
                        createdBy: widget.currentUserId,
                        name: _nameController.text,
                        description: _descriptionController.text,
                      ),
            child: isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }
}
