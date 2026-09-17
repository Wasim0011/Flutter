import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/start_chat_controller.dart';

class StartChatPage extends ConsumerStatefulWidget {
  const StartChatPage({super.key});

  @override
  ConsumerState<StartChatPage> createState() => _StartChatPageState();
}

class _StartChatPageState extends ConsumerState<StartChatPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String? _validatePhone(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) return 'Enter a phone number';
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(input)) {
      return 'Include the country code, e.g. +919876543210';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StartChatState state = ref.watch(startChatControllerProvider);
    final bool isSearching = state is StartChatSearching;
    final String? currentUserId = ref.watch(authStateChangesProvider).value?.id;

    ref.listen<StartChatState>(startChatControllerProvider, (previous, next) {
      if (next is StartChatReady) {
        context.pushReplacement(
          AppRoutes.conversation,
          extra: {
            'conversationId': next.conversation.id,
            'title': next.conversation.otherParticipantId(currentUserId ?? '') ?? 'Chat',
          },
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !isSearching,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+919876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                if (state is StartChatFailed)
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
                  onPressed: (isSearching || currentUserId == null)
                      ? null
                      : () {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    ref.read(startChatControllerProvider.notifier).startChatWithPhoneNumber(
                      currentUserId: currentUserId,
                      phoneNumber: _phoneController.text.trim(),
                    );
                  },
                  child: isSearching
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                      : const Text('Start chat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}