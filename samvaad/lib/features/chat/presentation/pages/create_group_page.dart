import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/create_group_controller.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> _participantPhoneNumbers = [];

  void _addParticipant() {
    final String input = _phoneController.text.trim();
    if (input.isEmpty || _participantPhoneNumbers.contains(input)) return;
    setState(() {
      _participantPhoneNumbers.add(input);
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CreateGroupState state = ref.watch(createGroupControllerProvider);
    final bool isSubmitting = state is CreateGroupSubmitting;
    final String? currentUserId = ref.watch(authStateChangesProvider).value?.id;

    ref.listen<CreateGroupState>(createGroupControllerProvider, (previous, next) {
      if (next is CreateGroupReady) {
        context.pushReplacement(
          AppRoutes.conversation,
          extra: {
            'conversationId': next.conversation.id,
            'title': next.conversation.title ?? 'Group',
          },
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Group name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Add by phone number',
                        hintText: '+919876543210',
                      ),
                      onSubmitted: (_) => _addParticipant(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addParticipant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _participantPhoneNumbers
                    .map((phone) => Chip(
                  label: Text(phone),
                  onDeleted: () => setState(() => _participantPhoneNumbers.remove(phone)),
                ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (state is CreateGroupFailed)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.message,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: (isSubmitting || currentUserId == null)
                    ? null
                    : () {
                  ref.read(createGroupControllerProvider.notifier).create(
                    currentUserId: currentUserId,
                    participantPhoneNumbers: _participantPhoneNumbers,
                    title: _titleController.text,
                  );
                },
                child: isSubmitting
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
                    : const Text('Create group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}