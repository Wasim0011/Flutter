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
/// An earlier version of this bridged the auth stream into GoRouter's
/// own `refreshListenable` mechanism instead. That works in principle,
/// but introduces two independent stream subscriptions racing each
/// other (the listenable's, and the provider's own), with no guarantee
/// `redirect` re-runs only after the provider has actually resolved.
/// Watching the provider directly removes that race: `redirect` always
/// sees the same already-computed `authState` the rest of this
/// function saw when it built.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Samvaad's declarative route table.
///
/// Watches `authStateChangesProvider` directly (not just inside
/// `redirect`) so that Riverpod itself rebuilds this provider — and
/// therefore produces a fresh `GoRouter` whose `redirect` closes over
/// an already-resolved `authState` — whenever auth state changes.
///
/// An earlier version of this bridged the auth stream into GoRouter's
/// own `refreshListenable` mechanism instead. That works in principle,
/// but introduces two independent stream subscriptions racing each
/// other (the listenable's, and the provider's own), with no guarantee
/// `redirect` re-runs only after the provider has actually resolved.
/// Watching the provider directly removes that race: `redirect` always
/// sees the same already-computed `authState` the rest of this
/// function saw when it built.

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
  /// An earlier version of this bridged the auth stream into GoRouter's
  /// own `refreshListenable` mechanism instead. That works in principle,
  /// but introduces two independent stream subscriptions racing each
  /// other (the listenable's, and the provider's own), with no guarantee
  /// `redirect` re-runs only after the provider has actually resolved.
  /// Watching the provider directly removes that race: `redirect` always
  /// sees the same already-computed `authState` the rest of this
  /// function saw when it built.
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

String _$appRouterHash() => r'32852bbd8b8f466aa5b56c23e3ac1193e9f02408';
