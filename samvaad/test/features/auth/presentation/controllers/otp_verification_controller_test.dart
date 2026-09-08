import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/domain/repositories/auth_repository.dart';
import 'package:samvaad/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:samvaad/features/auth/presentation/providers/auth_providers.dart';
import '../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo as AuthRepository),
      ],
    );
  });

  tearDown(() {
    fakeRepo.dispose();
    container.dispose();
  });

  test('starts in idle state', () {
    expect(container.read(otpVerificationControllerProvider), isA<OtpVerificationIdle>());
  });

  test('submit() succeeds with the correct OTP', () async {
    await container.read(otpVerificationControllerProvider.notifier).submit(
      verificationId: 'fake-verification-id',
      otp: '123456',
    );

    final state = container.read(otpVerificationControllerProvider);
    expect(state, isA<OtpVerificationSucceeded>());
  });

  test('submit() fails with an incorrect OTP', () async {
    await container.read(otpVerificationControllerProvider.notifier).submit(
      verificationId: 'fake-verification-id',
      otp: '000000',
    );

    final state = container.read(otpVerificationControllerProvider);
    expect(state, isA<OtpVerificationFailed>());
  });

  test('reset() returns to idle', () async {
    await container.read(otpVerificationControllerProvider.notifier).submit(
      verificationId: 'fake-verification-id',
      otp: '123456',
    );
    container.read(otpVerificationControllerProvider.notifier).reset();

    expect(container.read(otpVerificationControllerProvider), isA<OtpVerificationIdle>());
  });

  test('ResendCooldownController starts at 30 and can be restarted', () {
    final int initial = container.read(resendCooldownControllerProvider);
    expect(initial, 30);

    // restart() resets to 30 regardless of current countdown position —
    // we don't assert on tick timing here to keep this test fast and
    // avoid depending on real Timer delays.
    container.read(resendCooldownControllerProvider.notifier).restart();
    expect(container.read(resendCooldownControllerProvider), 30);
  });
}