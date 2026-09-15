import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:samvaad/features/chat/presentation/controllers/create_group_controller.dart';
import 'package:samvaad/features/chat/presentation/providers/chat_providers.dart';
import '../../../auth/fakes/fake_user_profile_repository.dart';
import '../../fakes/fake_chat_repository.dart';

void main() {
  late FakeUserProfileRepository fakeProfileRepo;
  late FakeChatRepository fakeChatRepo;
  late ProviderContainer container;

  const String currentUserId = 'user-a';

  setUp(() async {
    fakeProfileRepo = FakeUserProfileRepository();
    fakeChatRepo = FakeChatRepository();
    container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        chatRepositoryProvider.overrideWithValue(fakeChatRepo),
      ],
    );

    await fakeProfileRepo.ensureUserDocument(userId: 'user-b', phoneNumber: '+911111111111');
    await fakeProfileRepo.ensureUserDocument(userId: 'user-c', phoneNumber: '+912222222222');
  });

  tearDown(() {
    fakeChatRepo.dispose();
    container.dispose();
  });

  test('starts in idle state', () {
    expect(container.read(createGroupControllerProvider), isA<CreateGroupIdle>());
  });

  test('fails with no participants', () async {
    await container.read(createGroupControllerProvider.notifier).create(
      currentUserId: currentUserId,
      participantPhoneNumbers: const [],
      title: 'Team',
    );

    expect(container.read(createGroupControllerProvider), isA<CreateGroupFailed>());
  });

  test('fails with an empty title', () async {
    await container.read(createGroupControllerProvider.notifier).create(
      currentUserId: currentUserId,
      participantPhoneNumbers: const ['+911111111111'],
      title: '   ',
    );

    expect(container.read(createGroupControllerProvider), isA<CreateGroupFailed>());
  });

  test('fails when a phone number doesn\'t resolve to a known user', () async {
    await container.read(createGroupControllerProvider.notifier).create(
      currentUserId: currentUserId,
      participantPhoneNumbers: const ['+919999999999'],
      title: 'Team',
    );

    expect(container.read(createGroupControllerProvider), isA<CreateGroupFailed>());
  });

  test('succeeds and resolves all phone numbers to user ids', () async {
    await container.read(createGroupControllerProvider.notifier).create(
      currentUserId: currentUserId,
      participantPhoneNumbers: const ['+911111111111', '+912222222222'],
      title: 'Team',
    );

    final state = container.read(createGroupControllerProvider);
    expect(state, isA<CreateGroupReady>());
    final conversation = (state as CreateGroupReady).conversation;
    expect(conversation.participantIds, containsAll(['user-b', 'user-c', currentUserId]));
    expect(conversation.title, 'Team');
  });
}