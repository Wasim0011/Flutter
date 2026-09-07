import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/core/error/failure.dart';
import '../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  group('sendOtp', () {
    test('succeeds with a verification id by default', () async {
      final result = await repository.sendOtp('+919999999999');

      expect(result.isSuccess, isTrue);
    });

    test('returns the configured failure when set', () async {
      repository.sendOtpFailure = const Failure.network('offline');

      final result = await repository.sendOtp('+919999999999');

      expect(result.isFailure, isTrue);
    });
  });

  group('verifyOtp', () {
    test('succeeds with the correct OTP and emits on authStateChanges', () async {
      final authStates = <dynamic>[];
      final sub = repository.authStateChanges().listen(authStates.add);

      final result = await repository.verifyOtp(
        verificationId: 'fake-verification-id',
        otp: '123456',
      );

      expect(result.isSuccess, isTrue);
      await Future<void>.delayed(Duration.zero); // let the stream emit
      expect(authStates, hasLength(1));
      expect(authStates.first, isNotNull);

      await sub.cancel();
    });

    test('fails with an incorrect OTP', () async {
      final result = await repository.verifyOtp(
        verificationId: 'fake-verification-id',
        otp: 'wrong',
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('signOut', () {
    test('succeeds and emits null on authStateChanges', () async {
      final authStates = <dynamic>[];
      final sub = repository.authStateChanges().listen(authStates.add);

      await repository.verifyOtp(verificationId: 'x', otp: '123456');
      final result = await repository.signOut();

      expect(result.isSuccess, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(authStates.last, isNull);

      await sub.cancel();
    });
  });
}