// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide [AuthRepository] instance.
///
/// Everything that needs to sign in/out or check auth state depends on
/// this provider, not on `FirebaseAuthRepository` directly — tests
/// override this single provider with a fake, and nothing else in the
/// dependency graph needs to change.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// The app-wide [AuthRepository] instance.
///
/// Everything that needs to sign in/out or check auth state depends on
/// this provider, not on `FirebaseAuthRepository` directly — tests
/// override this single provider with a fake, and nothing else in the
/// dependency graph needs to change.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// The app-wide [AuthRepository] instance.
  ///
  /// Everything that needs to sign in/out or check auth state depends on
  /// this provider, not on `FirebaseAuthRepository` directly — tests
  /// override this single provider with a fake, and nothing else in the
  /// dependency graph needs to change.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'3a723e34e8f0950a5e5ba88000eacf0b61082153';

/// Live stream of the current auth state, for the router guard
/// (Milestone 2.6) and any widget that needs to react to sign-in/out.

@ProviderFor(authStateChanges)
final authStateChangesProvider = AuthStateChangesProvider._();

/// Live stream of the current auth state, for the router guard
/// (Milestone 2.6) and any widget that needs to react to sign-in/out.

final class AuthStateChangesProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  /// Live stream of the current auth state, for the router guard
  /// (Milestone 2.6) and any widget that needs to react to sign-in/out.
  AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'389bdea8d9eb45c34594a8aa5aa2da48ea7941cb';
