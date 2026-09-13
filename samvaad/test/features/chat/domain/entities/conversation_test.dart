import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/chat/domain/entities/conversation.dart';

void main() {
  group('Conversation', () {
    final DateTime createdAt = DateTime(2026, 1, 1);

    test('isGroup reflects type correctly', () {
      final direct = Conversation(
        id: 'c1',
        type: ConversationType.direct,
        participantIds: const ['u1', 'u2'],
        createdAt: createdAt,
      );
      final group = Conversation(
        id: 'c2',
        type: ConversationType.group,
        participantIds: const ['u1', 'u2', 'u3'],
        createdAt: createdAt,
        title: 'Team',
      );

      expect(direct.isGroup, isFalse);
      expect(group.isGroup, isTrue);
    });

    test('otherParticipantId returns the non-current participant for direct chats', () {
      final direct = Conversation(
        id: 'c1',
        type: ConversationType.direct,
        participantIds: const ['u1', 'u2'],
        createdAt: createdAt,
      );

      expect(direct.otherParticipantId('u1'), 'u2');
      expect(direct.otherParticipantId('u2'), 'u1');
    });

    test('otherParticipantId returns null for groups', () {
      final group = Conversation(
        id: 'c2',
        type: ConversationType.group,
        participantIds: const ['u1', 'u2', 'u3'],
        createdAt: createdAt,
        title: 'Team',
      );

      expect(group.otherParticipantId('u1'), isNull);
    });

    test('equality accounts for participantIds order', () {
      final a = Conversation(
        id: 'c1',
        type: ConversationType.direct,
        participantIds: const ['u1', 'u2'],
        createdAt: createdAt,
      );
      final b = Conversation(
        id: 'c1',
        type: ConversationType.direct,
        participantIds: const ['u2', 'u1'],
        createdAt: createdAt,
      );

      expect(a, isNot(equals(b)));
    });
  });
}