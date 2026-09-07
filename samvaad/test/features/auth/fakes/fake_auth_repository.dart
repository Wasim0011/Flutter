import 'dart:async';

import 'package:samvaad/core/error/failure.dart';
import 'package:samvaad/core/error/result.dart';
import 'package:samvaad/features/auth/domain/entities/app_user.dart';
import 'package:samvaad/features/auth/domain/repositories/auth_repository.dart';

/// In-memory fake for [AuthRepository], used by tests instead of
/// Firebase. Configurable via the fields below so a single test can
/// simulate success, failure, or a specific stored OTP without any
/// mocking framework or network/platform dependency.
class FakeAuthRepository implements AuthRepository {
  /// The OTP that [verifyOtp] will accept.
  String correctOtp = '123456';

  /// If set, [sendOtp] returns this failure instead of succeeding.
  Failure? sendOtpFailure;

  /// If set, [verifyOtp] returns this failure instead of checking the OTP.
  Failure? verifyOtpFailure;

  final StreamController<AppUser?> _authStateController =
  StreamController<AppUser?>.broadcast();

  @override
  Future<Result<PhoneVerificationSent>> sendOtp(String phoneNumber) async {
    if (sendOtpFailure != null) {
      return Result.failure(sendOtpFailure!);
    }
    return const Result.success(
      PhoneVerificationSent(verificationId: 'fake-verification-id'),
    );
  }

  @override
  Future<Result<AppUser>> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    if (verifyOtpFailure != null) {
      return Result.failure(verifyOtpFailure!);
    }
    if (otp != correctOtp) {
      return const Result.failure(Failure.validation('That code is incorrect.'));
    }

    const AppUser user = AppUser(id: 'fake-uid', phoneNumber: '+919999999999');
    _authStateController.add(user);
    return const Result.success(user);
  }

  @override
  Stream<AppUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<Result<void>> signOut() async {
    _authStateController.add(null);
    return const Result.success(null);
  }

  /// Call in `tearDown` to release the stream controller between tests.
  void dispose() => _authStateController.close();
}