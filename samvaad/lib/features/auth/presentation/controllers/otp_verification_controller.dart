import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers_export.dart';

part 'otp_verification_controller.g.dart';

/// UI-facing state for OTP verification, mirroring the same
/// idle/submitting/failed pattern established in Milestone 2.4's
/// PhoneEntryController — kept consistent deliberately so both auth
/// screens read the same way to anyone reviewing this code.
sealed class OtpVerificationState {
  const OtpVerificationState();
}

final class OtpVerificationIdle extends OtpVerificationState {
  const OtpVerificationIdle();
}

final class OtpVerificationSubmitting extends OtpVerificationState {
  const OtpVerificationSubmitting();
}

final class OtpVerificationFailed extends OtpVerificationState {
  const OtpVerificationFailed(this.message);
  final String message;
}

/// Emitted once on success — the widget listens for this to trigger
/// navigation to the app's home (wired in Milestone 2.6).
final class OtpVerificationSucceeded extends OtpVerificationState {
  const OtpVerificationSucceeded(this.user);
  final AppUser user;
}

@riverpod
class OtpVerificationController extends _$OtpVerificationController {
  @override
  OtpVerificationState build() => const OtpVerificationIdle();

  Future<void> submit({
    required String verificationId,
    required String otp,
  }) async {
    state = const OtpVerificationSubmitting();

    final AuthRepository repository = ref.read(authRepositoryProvider);
    final result = await repository.verifyOtp(
      verificationId: verificationId,
      otp: otp,
    );

    state = result.fold(
      onSuccess: (user) => OtpVerificationSucceeded(user),
      onFailure: (failure) => OtpVerificationFailed(_messageFor(failure)),
    );
  }

  void reset() => state = const OtpVerificationIdle();

  String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    AuthenticationFailure(:final message) => message,
    PermissionFailure(:final message) => message,
    UnexpectedFailure(:final message) => message,
  };
}

/// Separate, independent controller for the resend-cooldown timer.
///
/// Kept apart from [OtpVerificationController] on purpose: the timer's
/// lifecycle (start on screen entry, tick every second, expire) has
/// nothing to do with verification success/failure, and mixing the two
/// concerns into one state class would force every verification state
/// transition to also carry a "secondsRemaining" field it doesn't need.
@riverpod
class ResendCooldownController extends _$ResendCooldownController {
  Timer? _timer;

  @override
  int build() {
    ref.onDispose(() => _timer?.cancel());
    _startCountdown();
    return _cooldownSeconds;
  }

  static const int _cooldownSeconds = 30;

  void _startCountdown() {
    state = _cooldownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state <= 1) {
        timer.cancel();
        state = 0;
      } else {
        state = state - 1;
      }
    });
  }

  /// Restarts the cooldown — called after a successful resend request.
  void restart() => _startCountdown();
}