import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/calling/domain/entities/call.dart';

void main() {
  group('Call', () {
    final DateTime createdAt = DateTime(2026, 1, 1);

    test('isGroup is false for exactly two participants', () {
      final call = Call(
        id: 'c1',
        roomName: 'room-1',
        callerId: 'u1',
        participantIds: const ['u1', 'u2'],
        status: CallStatus.ringing,
        createdAt: createdAt,
      );

      expect(call.isGroup, isFalse);
    });

    test('isGroup is true for more than two participants', () {
      final call = Call(
        id: 'c2',
        roomName: 'room-2',
        callerId: 'u1',
        participantIds: const ['u1', 'u2', 'u3'],
        status: CallStatus.ringing,
        createdAt: createdAt,
      );

      expect(call.isGroup, isTrue);
    });

    test('two instances with identical fields are equal', () {
      final a = Call(
        id: 'c1',
        roomName: 'room-1',
        callerId: 'u1',
        participantIds: const ['u1', 'u2'],
        status: CallStatus.ringing,
        createdAt: createdAt,
      );
      final b = Call(
        id: 'c1',
        roomName: 'room-1',
        callerId: 'u1',
        participantIds: const ['u1', 'u2'],
        status: CallStatus.ringing,
        createdAt: createdAt,
      );

      expect(a, equals(b));
    });

    test('conversationId defaults to null', () {
      final call = Call(
        id: 'c1',
        roomName: 'room-1',
        callerId: 'u1',
        participantIds: const ['u1', 'u2'],
        status: CallStatus.ringing,
        createdAt: createdAt,
      );

      expect(call.conversationId, isNull);
    });
  });
}