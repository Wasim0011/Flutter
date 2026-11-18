// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ensures the brand splash animation has enough time to complete its
/// entrance sequence on initial app launch before the router redirects.
///
/// Kept alive so subsequent session re-evaluations (such as completing
/// onboarding) do not re-trigger another multi-second hold. Override this
/// provider in widget/integration tests so `pumpAndSettle` resolves immediately.

@ProviderFor(splashHold)
final splashHoldProvider = SplashHoldProvider._();

/// Ensures the brand splash animation has enough time to complete its
/// entrance sequence on initial app launch before the router redirects.
///
/// Kept alive so subsequent session re-evaluations (such as completing
/// onboarding) do not re-trigger another multi-second hold. Override this
/// provider in widget/integration tests so `pumpAndSettle` resolves immediately.

final class SplashHoldProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Ensures the brand splash animation has enough time to complete its
  /// entrance sequence on initial app launch before the router redirects.
  ///
  /// Kept alive so subsequent session re-evaluations (such as completing
  /// onboarding) do not re-trigger another multi-second hold. Override this
  /// provider in widget/integration tests so `pumpAndSettle` resolves immediately.
  SplashHoldProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashHoldProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashHoldHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return splashHold(ref);
  }
}

String _$splashHoldHash() => r'e95fa762b705ecc86fbcf7c2d1121d42ad7176a4';
