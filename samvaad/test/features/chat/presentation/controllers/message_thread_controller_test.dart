import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/chat/domain/entities/message.dart';
import 'package:samvaad/features/chat/presentation/controllers/message_thread_controller.dart';
import 'package:samvaad/features/chat/presentation/providers/chat_providers.dart';
import '../../fakes/fake_chat_repository.dart';

void main() {
  late FakeChatRepository fakeChatRepo;
  late ProviderContainer container;

  const String conversationId = 'conv-1';
  const String senderId = 'user-a';

  setUp(() {
    fakeChatRepo = FakeChatRepository();
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(fakeChatRepo),
      ],
    );
  });

  tearDown(() {
    fakeChatRepo.dispose();
    container.dispose();
  });

  group('messageThreadProvider', () {
    test('emits an empty list for a conversation with no messages', () async {
      // messageThreadProvider is autoDispose — a bare container.read()
      // doesn't keep it alive across the async gap before the stream's
      // first event arrives, so Riverpod can (and did) dispose it
      // mid-flight. container.listen() establishes a real subscriber,
      // keeping the provider alive for the duration of this test.
      final sub = container.listen(
        messageThreadProvider(conversationId),
            (previous, next) {},
      );
      addTearDown(sub.close);

      final List<Message> messages = await container.read(
        messageThreadProvider(conversationId).future,
      );

      expect(messages, isEmpty);
    });

    test('emits messages after one is sent', () async {
      final sub = container.listen(
        messageThreadProvider(conversationId),
            (previous, next) {},
      );
      addTearDown(sub.close);

      await fakeChatRepo.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: 'hello',
      );

      await Future<void>.delayed(Duration.zero);

      final AsyncValue<List<Message>> state = container.read(
        messageThreadProvider(conversationId),
      );
      expect(state.value, hasLength(1));
      expect(state.value!.first.text, 'hello');
      expect(state.value!.first.senderId, senderId);
    });
  });

  group('SendMessageController', () {
    test('starts in idle state', () {
      expect(container.read(sendMessageControllerProvider), isA<SendMessageIdle>());
    });

    test('send() returns to idle on success', () async {
      await container.read(sendMessageControllerProvider.notifier).send(
        conversationId: conversationId,
        senderId: senderId,
        text: 'hi there',
      );

      expect(container.read(sendMessageControllerProvider), isA<SendMessageIdle>());
    });

    test('send() does nothing for blank text', () async {
      final sub = container.listen(
        messageThreadProvider(conversationId),
            (previous, next) {},
      );
      addTearDown(sub.close);

      await container.read(sendMessageControllerProvider.notifier).send(
        conversationId: conversationId,
        senderId: senderId,
        text: '   ',
      );

      final List<Message> messages = await container.read(
        messageThreadProvider(conversationId).future,
      );
      expect(messages, isEmpty);
      expect(container.read(sendMessageControllerProvider), isA<SendMessageIdle>());
    });
  });
}