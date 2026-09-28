import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/edit_profile_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../providers/auth_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(String? name, String? bio) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = name ?? '';
    _bioController.text = bio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? userId = ref.watch(authStateChangesProvider).value?.id;

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AsyncValue<String?> nameAsync = ref.watch(displayNameProvider(userId));
    final AsyncValue<String?> bioAsync = ref.watch(bioProvider(userId));
    if (nameAsync.hasValue && bioAsync.hasValue) {
      _prefillIfNeeded(nameAsync.value, bioAsync.value);
    }

    final EditProfileState state = ref.watch(editProfileControllerProvider);
    final bool isSubmitting = state is EditProfileSubmitting;

    ref.listen<EditProfileState>(editProfileControllerProvider, (previous, next) {
      if (next is EditProfileSuccess && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell people a little about yourself',
                ),
              ),
              const SizedBox(height: 16),
              if (state is EditProfileFailed)
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
                onPressed: isSubmitting
                    ? null
                    : () => ref.read(editProfileControllerProvider.notifier).submit(
                  userId: userId,
                  displayName: _nameController.text,
                  bio: _bioController.text,
                ),
                child: isSubmitting
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}