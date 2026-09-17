import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/domain/entities/app_user.dart';
import 'package:samvaad/features/auth/presentation/controllers/onboarding_controller.dart';
import '../../fakes/fake_user_profile_repository.dart';

void main() {
  late FakeUserProfileRepository fakeRepo;
  late ProviderContainer container;

  const String userId = 'user-a';

  setUp(() {
    fakeRepo = FakeUserProfileRepository();
    container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('starts in idle state', () {
    expect(container.read(onboardingControllerProvider), isA<OnboardingIdle>());
  });

  test('submit() saves both name and preference, reaching complete', () async {
    await container.read(onboardingControllerProvider.notifier).submit(
      userId: userId,
      displayName: 'Wasim',
      preference: CommunicationPreference.textFirst,
    );

    expect(container.read(onboardingControllerProvider), isA<OnboardingComplete>());

    final name = await fakeRepo.getDisplayName(userId);
    final pref = await fakeRepo.getCommunicationPreference(userId);
    expect(name.fold(onSuccess: (n) => n, onFailure: (_) => null), 'Wasim');
    expect(pref.fold(onSuccess: (p) => p, onFailure: (_) => null),
        CommunicationPreference.textFirst);
  });

  test('hasCompletedOnboardingProvider is false before submit, true after', () async {
    final before = await container.read(hasCompletedOnboardingProvider(userId).future);
    expect(before, isFalse);

    await container.read(onboardingControllerProvider.notifier).submit(
      userId: userId,
      displayName: 'Wasim',
      preference: CommunicationPreference.noPreference,
    );

    // hasCompletedOnboardingProvider is a separate FutureProvider
    // instance keyed by userId; re-reading it fetches fresh since
    // it's autoDispose and this is a new read, not a cached one.
    final after = await container.read(hasCompletedOnboardingProvider(userId).future);
    expect(after, isTrue);
  });

  test('displayNameProvider reflects the saved name', () async {
    await container.read(onboardingControllerProvider.notifier).submit(
      userId: userId,
      displayName: 'Wasim',
      preference: CommunicationPreference.captionsFirst,
    );

    final name = await container.read(displayNameProvider(userId).future);
    expect(name, 'Wasim');
  });
}