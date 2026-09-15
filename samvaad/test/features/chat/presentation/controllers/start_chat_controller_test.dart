import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:samvaad/features/chat/presentation/controllers/start_chat_controller.dart';
import 'package:samvaad/features/chat/presentation/providers/chat_providers.dart';
import '../../../auth/fakes/fake_user_profile_repository.dart';
import '../../fakes/fake_chat_repository.dart';

void main() {
  late FakeUserProfileRepository fakeProfileRepo;
  late FakeChatRepository fakeChatRepo;
  late ProviderContainer container;

  const String currentUserId = 'user-a';
  const String otherUserId = 'user-b';
  const String otherPhoneNumber = '+919999999998';

  setUp(() async {
    fakeProfileRepo = FakeUserProfileRepository();
    fakeChatRepo = FakeChatRepository();
    container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        chatRepositoryProvider.overrideWithValue(fakeChatRepo),
      ],
    );

    // Register the "other" user so phone lookup can find them.
    await fakeProfileRepo.ensureUserDocument(
      userId: otherUserId,
      phoneNumber: otherPhoneNumber,
    );
  });

  tearDown(() {
    fakeChatRepo.dispose();
    container.dispose();
  });

  test('starts in idle state', () {
    expect(container.read(startChatControllerProvider), isA<StartChatIdle>());
  });

  test('succeeds when the phone number matches a known user', () async {
    await container.read(startChatControllerProvider.notifier).startChatWithPhoneNumber(
      currentUserId: currentUserId,
      phoneNumber: otherPhoneNumber,
    );

    final state = container.read(startChatControllerProvider);
    expect(state, isA<StartChatReady>());
    expect((state as StartChatReady).conversation.participantIds, contains(otherUserId));
  });

  test('fails when no user matches the phone number', () async {
    await container.read(startChatControllerProvider.notifier).startChatWithPhoneNumber(
      currentUserId: currentUserId,
      phoneNumber: '+910000000000',
    );

    expect(container.read(startChatControllerProvider), isA<StartChatFailed>());
  });

  test('fails when the phone number belongs to the current user', () async {
    await fakeProfileRepo.ensureUserDocument(
      userId: currentUserId,
      phoneNumber: '+919999999999',
    );

    await container.read(startChatControllerProvider.notifier).startChatWithPhoneNumber(
      currentUserId: currentUserId,
      phoneNumber: '+919999999999',
    );

    expect(container.read(startChatControllerProvider), isA<StartChatFailed>());
  });

  test('reset() returns to idle', () async {
    await container.read(startChatControllerProvider.notifier).startChatWithPhoneNumber(
      currentUserId: currentUserId,
      phoneNumber: otherPhoneNumber,
    );
    container.read(startChatControllerProvider.notifier).reset();

    expect(container.read(startChatControllerProvider), isA<StartChatIdle>());
  });
}