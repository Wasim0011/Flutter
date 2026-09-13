// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Samvaad's declarative route table.
///
/// Watches `authStateChangesProvider` directly (not just inside
/// `redirect`) so that Riverpod itself rebuilds this provider — and
/// therefore produces a fresh `GoRouter` whose `redirect` closes over
/// an already-resolved `authState` — whenever auth state changes.
///
/// Milestone 2.7 adds a second reactive dependency the same way:
/// `redirect` also watches `hasCompletedOnboardingProvider` for the
/// current user, so a signed-in user who hasn't set a communication
/// preference yet is routed to onboarding before reaching anywhere else.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Samvaad's declarative route table.
///
/// Watches `authStateChangesProvider` directly (not just inside
/// `redirect`) so that Riverpod itself rebuilds this provider — and
/// therefore produces a fresh `GoRouter` whose `redirect` closes over
/// an already-resolved `authState` — whenever auth state changes.
///
/// Milestone 2.7 adds a second reactive dependency the same way:
/// `redirect` also watches `hasCompletedOnboardingProvider` for the
/// current user, so a signed-in user who hasn't set a communication
/// preference yet is routed to onboarding before reaching anywhere else.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Samvaad's declarative route table.
  ///
  /// Watches `authStateChangesProvider` directly (not just inside
  /// `redirect`) so that Riverpod itself rebuilds this provider — and
  /// therefore produces a fresh `GoRouter` whose `redirect` closes over
  /// an already-resolved `authState` — whenever auth state changes.
  ///
  /// Milestone 2.7 adds a second reactive dependency the same way:
  /// `redirect` also watches `hasCompletedOnboardingProvider` for the
  /// current user, so a signed-in user who hasn't set a communication
  /// preference yet is routed to onboarding before reaching anywhere else.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'02a2180b9e997ca0814b056cee308b5a90137bfb';
