import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/chat/domain/entities/message.dart';

void main() {
  group('Message', () {
    test('two instances with identical fields are equal', () {
      final DateTime now = DateTime(2026, 1, 1);
      final a = Message(id: 'm1', conversationId: 'c1', senderId: 'u1', text: 'hi', sentAt: now);
      final b = Message(id: 'm1', conversationId: 'c1', senderId: 'u1', text: 'hi', sentAt: now);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('defaults to MessageType.text', () {
      final message = Message(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'hi',
        sentAt: DateTime(2026, 1, 1),
      );

      expect(message.type, MessageType.text);
    });
  });
}