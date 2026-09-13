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

  AppUser? _currentUser;
  final List<MultiStreamController<AppUser?>> _controllers = [];

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
    _emit(user);
    return const Result.success(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    // `Stream.multi` runs this callback once PER listener (unlike
    // `StreamController.broadcast`'s `onListen`, which only fires on
    // the very first subscriber). Real Firebase Auth's
    // `authStateChanges()` gives every new listener the current state
    // immediately on subscribe — this app has more than one
    // subscriber to this stream (the auth-state provider itself, and
    // the router's refresh listener), so a fake that only replays to
    // the first one silently starves whichever subscribes second.
    return Stream<AppUser?>.multi((controller) {
      controller.add(_currentUser);
      _controllers.add(controller);
      controller.onCancel = () => _controllers.remove(controller);
    });
  }

  @override
  Future<Result<void>> signOut() async {
    _emit(null);
    return const Result.success(null);
  }

  void _emit(AppUser? user) {
    _currentUser = user;
    for (final controller in List<MultiStreamController<AppUser?>>.of(_controllers)) {
      controller.add(user);
    }
  }

  /// Call in `tearDown` to release all active listeners between tests.
  void dispose() {
    for (final controller in List<MultiStreamController<AppUser?>>.of(_controllers)) {
      controller.close();
    }
    _controllers.clear();
  }
}