import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/domain/entities/app_user.dart';
import 'package:samvaad/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:samvaad/features/auth/presentation/providers/app_session.dart';
import 'package:samvaad/features/auth/presentation/providers/auth_providers.dart';
import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_user_profile_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
  late ProviderContainer container;
  late ProviderSubscription<AppSession> subscription;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeUserProfileRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
    subscription = container.listen(appSessionProvider, (previous, next) {});
  });

  tearDown(() {
    subscription.close();
    auth.dispose();
    container.dispose();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));
  Future<void> signIn() => auth.verifyOtp(verificationId: 'x', otp: '123456');

  test('signed out when nobody is signed in', () async {
    await settle();
    expect(container.read(appSessionProvider), isA<AppSessionSignedOut>());
  });

  test('signed in without a saved preference needs onboarding', () async {
    await signIn();
    await settle();
    expect(
      container.read(appSessionProvider),
      isA<AppSessionNeedsOnboarding>(),
    );
  });

  test('signed in with a saved preference is ready', () async {
    await profiles.saveCommunicationPreference(
      userId: 'fake-uid',
      preference: CommunicationPreference.textFirst,
    );
    await signIn();
    await settle();
    expect(container.read(appSessionProvider), isA<AppSessionReady>());
  });

  test('finishing onboarding moves needsOnboarding to ready', () async {
    await signIn();
    await settle();
    expect(
      container.read(appSessionProvider),
      isA<AppSessionNeedsOnboarding>(),
    );

    await profiles.saveCommunicationPreference(
      userId: 'fake-uid',
      preference: CommunicationPreference.noPreference,
    );
    container.invalidate(hasCompletedOnboardingProvider('fake-uid'));
    await settle();
    expect(container.read(appSessionProvider), isA<AppSessionReady>());
  });

  test('signing out returns to signed out', () async {
    await signIn();
    await settle();
    await auth.signOut();
    await settle();
    expect(container.read(appSessionProvider), isA<AppSessionSignedOut>());
  });
}
