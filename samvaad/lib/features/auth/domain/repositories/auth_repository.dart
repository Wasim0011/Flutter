import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

/// Contract for phone-number authentication, implemented by the data
/// layer (Firebase Auth, in Milestone 2.3) and consumed by the
/// presentation layer via Riverpod providers.
///
/// Phone OTP is inherently a two-step flow — send a code, then verify
/// it — so this interface mirrors that shape rather than exposing a
/// single "signIn" call. `verificationId` is the thread connecting the
/// two steps; it's an opaque string as far as the domain/presentation
/// layers are concerned, even though Firebase Auth is what actually
/// produces and consumes it underneath.
abstract interface class AuthRepository {
  /// Sends a one-time verification code to [phoneNumber] (must be
  /// E.164-formatted, e.g. "+919876543210").
  ///
  /// On success, returns a [PhoneVerificationSent] containing the
  /// `verificationId` needed for [verifyOtp]. On failure, returns a
  /// [Failure] (e.g. invalid number format, network issue, rate limit).
  Future<Result<PhoneVerificationSent>> sendOtp(String phoneNumber);

  /// Verifies [otp] against the code sent for [verificationId].
  ///
  /// On success, returns the signed-in [AppUser]. On failure (wrong
  /// code, expired code, network issue), returns a [Failure].
  Future<Result<AppUser>> verifyOtp({
    required String verificationId,
    required String otp,
  });

  /// The currently signed-in user, or null if no one is signed in.
  /// A stream so the app can react immediately to sign-in/sign-out
  /// events (used by the router guard in Milestone 2.6).
  Stream<AppUser?> authStateChanges();

  /// Signs the current user out.
  Future<Result<void>> signOut();
}

/// Result of successfully requesting an OTP: the identifier needed to
/// complete verification in a follow-up call to [AuthRepository.verifyOtp].
class PhoneVerificationSent {
  const PhoneVerificationSent({required this.verificationId});

  final String verificationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is PhoneVerificationSent &&
              other.verificationId == verificationId);

  @override
  int get hashCode => verificationId.hashCode;

  @override
  String toString() => 'PhoneVerificationSent(verificationId: $verificationId)';
}