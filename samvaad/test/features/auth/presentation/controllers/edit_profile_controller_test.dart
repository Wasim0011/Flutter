import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/presentation/controllers/edit_profile_controller.dart';
import 'package:samvaad/features/auth/presentation/controllers/onboarding_controller.dart';
import '../../fakes/fake_user_profile_repository.dart';

void main() {
  late FakeUserProfileRepository fakeRepo;
  late ProviderContainer container;

  const String userId = 'user-a';

  setUp(() {
    fakeRepo = FakeUserProfileRepository();
    container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('fails with an empty display name', () async {
    await container
        .read(editProfileControllerProvider.notifier)
        .submit(userId: userId, displayName: '  ', bio: 'hello');

    expect(
      container.read(editProfileControllerProvider),
      isA<EditProfileFailed>(),
    );
  });

  test('succeeds and saves both name and bio', () async {
    await container
        .read(editProfileControllerProvider.notifier)
        .submit(userId: userId, displayName: 'Wasim', bio: 'Flutter developer');

    expect(
      container.read(editProfileControllerProvider),
      isA<EditProfileSuccess>(),
    );

    final name = await fakeRepo.getDisplayName(userId);
    final bio = await fakeRepo.getBio(userId);
    expect(name.fold(onSuccess: (n) => n, onFailure: (_) => null), 'Wasim');
    expect(
      bio.fold(onSuccess: (b) => b, onFailure: (_) => null),
      'Flutter developer',
    );
  });
}
