// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_verification_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OtpVerificationController)
final otpVerificationControllerProvider = OtpVerificationControllerProvider._();

final class OtpVerificationControllerProvider
    extends $NotifierProvider<OtpVerificationController, OtpVerificationState> {
  OtpVerificationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'otpVerificationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$otpVerificationControllerHash();

  @$internal
  @override
  OtpVerificationController create() => OtpVerificationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OtpVerificationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OtpVerificationState>(value),
    );
  }
}

String _$otpVerificationControllerHash() =>
    r'7591ec66d122dfd0fddca064e2f0a62c44625f12';

abstract class _$OtpVerificationController
    extends $Notifier<OtpVerificationState> {
  OtpVerificationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OtpVerificationState, OtpVerificationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OtpVerificationState, OtpVerificationState>,
              OtpVerificationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Separate, independent controller for the resend-cooldown timer.
///
/// Kept apart from [OtpVerificationController] on purpose: the timer's
/// lifecycle (start on screen entry, tick every second, expire) has
/// nothing to do with verification success/failure, and mixing the two
/// concerns into one state class would force every verification state
/// transition to also carry a "secondsRemaining" field it doesn't need.

@ProviderFor(ResendCooldownController)
final resendCooldownControllerProvider = ResendCooldownControllerProvider._();

/// Separate, independent controller for the resend-cooldown timer.
///
/// Kept apart from [OtpVerificationController] on purpose: the timer's
/// lifecycle (start on screen entry, tick every second, expire) has
/// nothing to do with verification success/failure, and mixing the two
/// concerns into one state class would force every verification state
/// transition to also carry a "secondsRemaining" field it doesn't need.
final class ResendCooldownControllerProvider
    extends $NotifierProvider<ResendCooldownController, int> {
  /// Separate, independent controller for the resend-cooldown timer.
  ///
  /// Kept apart from [OtpVerificationController] on purpose: the timer's
  /// lifecycle (start on screen entry, tick every second, expire) has
  /// nothing to do with verification success/failure, and mixing the two
  /// concerns into one state class would force every verification state
  /// transition to also carry a "secondsRemaining" field it doesn't need.
  ResendCooldownControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resendCooldownControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resendCooldownControllerHash();

  @$internal
  @override
  ResendCooldownController create() => ResendCooldownController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$resendCooldownControllerHash() =>
    r'4e4ada2cbc8eaafd59477bffad8c41409067de33';

/// Separate, independent controller for the resend-cooldown timer.
///
/// Kept apart from [OtpVerificationController] on purpose: the timer's
/// lifecycle (start on screen entry, tick every second, expire) has
/// nothing to do with verification success/failure, and mixing the two
/// concerns into one state class would force every verification state
/// transition to also carry a "secondsRemaining" field it doesn't need.

abstract class _$ResendCooldownController extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
