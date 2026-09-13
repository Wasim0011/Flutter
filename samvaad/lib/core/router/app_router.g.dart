// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Samvaad's declarative route table, now provided via Riverpod so
/// `redirect` can react to live auth state (Milestone 2.3's
/// `authStateChangesProvider`) — this is exactly the mechanical
/// upgrade anticipated back in Milestone 4 of Phase 1, not a redesign.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Samvaad's declarative route table, now provided via Riverpod so
/// `redirect` can react to live auth state (Milestone 2.3's
/// `authStateChangesProvider`) — this is exactly the mechanical
/// upgrade anticipated back in Milestone 4 of Phase 1, not a redesign.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Samvaad's declarative route table, now provided via Riverpod so
  /// `redirect` can react to live auth state (Milestone 2.3's
  /// `authStateChangesProvider`) — this is exactly the mechanical
  /// upgrade anticipated back in Milestone 4 of Phase 1, not a redesign.
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

String _$appRouterHash() => r'913764e2a1e43f608f8942614d9a968a0dbf2423';
