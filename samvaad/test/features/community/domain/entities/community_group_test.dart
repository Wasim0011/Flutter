import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/community/domain/entities/community_group.dart';

void main() {
  group('CommunityGroup', () {
    final DateTime createdAt = DateTime(2026, 1, 1);

    test('memberCount reflects memberIds length', () {
      final group = CommunityGroup(
        id: 'g1',
        name: 'Test',
        description: 'desc',
        createdBy: 'u1',
        memberIds: const ['u1', 'u2', 'u3'],
        createdAt: createdAt,
      );

      expect(group.memberCount, 3);
    });

    test('isMember correctly checks membership', () {
      final group = CommunityGroup(
        id: 'g1',
        name: 'Test',
        description: 'desc',
        createdBy: 'u1',
        memberIds: const ['u1', 'u2'],
        createdAt: createdAt,
      );

      expect(group.isMember('u1'), isTrue);
      expect(group.isMember('u3'), isFalse);
    });
  });
}