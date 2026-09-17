import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nameController = TextEditingController();
  CommunicationPreference? _selected;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty && _selected != null;

  void _submit() {
    final CommunicationPreference? preference = _selected;
    final String name = _nameController.text.trim();
    if (preference == null || name.isEmpty) return;
    ref.read(onboardingControllerProvider.notifier).submit(
      userId: widget.userId,
      displayName: name,
      preference: preference,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OnboardingState state = ref.watch(onboardingControllerProvider);
    final bool isSubmitting = state is OnboardingSubmitting;

    ref.listen<OnboardingState>(onboardingControllerProvider, (previous, next) {
      if (next is OnboardingComplete) {
        context.go(AppRoutes.splash);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'What should people call you?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Display name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              Text(
                'How do you communicate?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps Samvaad show you the right tools by default — '
                    'you can change it anytime in settings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              RadioGroup<CommunicationPreference>(
                groupValue: _selected,
                onChanged: (value) => setState(() => _selected = value),
                child: Column(
                  children: <Widget>[
                    _PreferenceTile(
                      value: CommunicationPreference.captionsFirst,
                      title: 'Captions first',
                      subtitle: 'I prefer live captions for speech and video',
                      selected: _selected == CommunicationPreference.captionsFirst,
                    ),
                    _PreferenceTile(
                      value: CommunicationPreference.signLanguage,
                      title: 'Sign language',
                      subtitle: 'I use or prefer sign language',
                      selected: _selected == CommunicationPreference.signLanguage,
                    ),
                    _PreferenceTile(
                      value: CommunicationPreference.textFirst,
                      title: 'Text first',
                      subtitle: 'I prefer typing over voice or video',
                      selected: _selected == CommunicationPreference.textFirst,
                    ),
                    _PreferenceTile(
                      value: CommunicationPreference.noPreference,
                      title: 'No preference',
                      subtitle: 'Show me everything, I\'ll decide as I go',
                      selected: _selected == CommunicationPreference.noPreference,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (state is OnboardingFailed)
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
              Semantics(
                button: true,
                enabled: _canSubmit && !isSubmitting,
                label: 'Continue',
                child: ElevatedButton(
                  onPressed: (!_canSubmit || isSubmitting) ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final CommunicationPreference value;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: RadioListTile<CommunicationPreference>(
        value: value,
        title: Text(title, style: theme.textTheme.titleLarge),
        subtitle: Text(subtitle),
      ),
    );
  }
}