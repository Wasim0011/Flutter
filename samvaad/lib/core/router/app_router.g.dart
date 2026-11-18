// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Samvaad's router, built exactly once for the life of the app.
///
/// It must NOT `ref.watch` anything: a rebuilt GoRouter resets navigation and
/// recreates the splash screen. Instead it listens to [appSessionProvider] and
/// pushes changes into a [ValueNotifier], which GoRouter's `refreshListenable`
/// uses to re-run `redirect` in place.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Samvaad's router, built exactly once for the life of the app.
///
/// It must NOT `ref.watch` anything: a rebuilt GoRouter resets navigation and
/// recreates the splash screen. Instead it listens to [appSessionProvider] and
/// pushes changes into a [ValueNotifier], which GoRouter's `refreshListenable`
/// uses to re-run `redirect` in place.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Samvaad's router, built exactly once for the life of the app.
  ///
  /// It must NOT `ref.watch` anything: a rebuilt GoRouter resets navigation and
  /// recreates the splash screen. Instead it listens to [appSessionProvider] and
  /// pushes changes into a [ValueNotifier], which GoRouter's `refreshListenable`
  /// uses to re-run `redirect` in place.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
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

String _$appRouterHash() => r'd9cd1bfc558f58a9f30e52fa4b4783daf1279d1f';
