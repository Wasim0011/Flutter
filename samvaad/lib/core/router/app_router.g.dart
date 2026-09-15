// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Samvaad's declarative route table.
///
/// Watches `authStateChangesProvider` directly so Riverpod rebuilds
/// this provider — and produces a fresh `GoRouter` whose `redirect`
/// closes over already-resolved auth/onboarding state — whenever
/// either changes.
///
/// Milestone 3.3 adds `home` as the true landing screen for a
/// signed-in, onboarded user. `splash` is now purely the loading/
/// decision screen shown only while auth or onboarding status is
/// still being determined — a fully resolved user is always bounced
/// off it toward `home`, never left there.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Samvaad's declarative route table.
///
/// Watches `authStateChangesProvider` directly so Riverpod rebuilds
/// this provider — and produces a fresh `GoRouter` whose `redirect`
/// closes over already-resolved auth/onboarding state — whenever
/// either changes.
///
/// Milestone 3.3 adds `home` as the true landing screen for a
/// signed-in, onboarded user. `splash` is now purely the loading/
/// decision screen shown only while auth or onboarding status is
/// still being determined — a fully resolved user is always bounced
/// off it toward `home`, never left there.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Samvaad's declarative route table.
  ///
  /// Watches `authStateChangesProvider` directly so Riverpod rebuilds
  /// this provider — and produces a fresh `GoRouter` whose `redirect`
  /// closes over already-resolved auth/onboarding state — whenever
  /// either changes.
  ///
  /// Milestone 3.3 adds `home` as the true landing screen for a
  /// signed-in, onboarded user. `splash` is now purely the loading/
  /// decision screen shown only while auth or onboarding status is
  /// still being determined — a fully resolved user is always bounced
  /// off it toward `home`, never left there.
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

String _$appRouterHash() => r'd04723ad062e4a0085e97a6a7563c75509aaf99e';
