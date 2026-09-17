import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/onboarding_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message.dart';
import '../controllers/message_thread_controller.dart';
import '../widgets/chat_display_style.dart';

/// The messaging screen for one conversation. Layout adapts to the
/// current user's communication preference via [ChatDisplayStyle] —
/// see that class for what each preference concretely changes.
class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({
    required this.conversationId,
    required this.title,
    super.key,
  });

  final String conversationId;
  final String title;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send(String currentUserId) {
    final String text = _textController.text;
    if (text.trim().isEmpty) return;
    ref.read(sendMessageControllerProvider.notifier).send(
      conversationId: widget.conversationId,
      senderId: currentUserId,
      text: text,
    );
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? currentUserId = ref.watch(authStateChangesProvider).value?.id;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AsyncValue<CommunicationPreference?> preferenceAsync =
    ref.watch(communicationPreferenceProvider(currentUserId));
    final ChatDisplayStyle style =
    ChatDisplayStyle.forPreference(preferenceAsync.value);

    final AsyncValue<List<Message>> messagesAsync =
    ref.watch(messageThreadProvider(widget.conversationId));
    final SendMessageState sendState = ref.watch(sendMessageControllerProvider);

    ref.listen<SendMessageState>(sendMessageControllerProvider, (previous, next) {
      if (next is SendMessageFailed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t send: ${next.message}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Couldn\'t load messages.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hello.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                // reverse: true anchors the list at the bottom and
                // keeps it there as new messages arrive — the standard
                // chat-list pattern, and simpler/more robust than
                // manually driving a ScrollController on every update.
                final List<Message> reversedMessages = messages.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final Message message = reversedMessages[index];
                    final bool isMine = message.senderId == currentUserId;
                    final Widget bubble = _MessageBubble(
                      message: message,
                      isMine: isMine,
                      style: style,
                    );
                    if (style.announceIncomingMessages && !isMine) {
                      return Semantics(liveRegion: true, child: bubble);
                    }
                    return bubble;
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Message'),
                      onSubmitted: (_) => _send(currentUserId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Send message',
                    enabled: sendState is! SendMessageSending,
                    child: IconButton.filled(
                      onPressed: sendState is SendMessageSending
                          ? null
                          : () => _send(currentUserId),
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.style,
  });

  final Message message;
  final bool isMine;
  final ChatDisplayStyle style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bubbleColor =
    isMine ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 17) * style.fontScale,
              ),
            ),
            if (style.showTimestamps) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(message.sentAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}