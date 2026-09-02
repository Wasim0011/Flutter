// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Temporary connectivity proof for Milestone 2.1 only.
///
/// This provider's only job is to confirm `Firebase.initializeApp()`
/// actually succeeded and the app is talking to the real Samvaad
/// Firebase project — not a placeholder or misconfigured one. It has
/// no role beyond this milestone and is deleted once Milestone 2.2's
/// real AuthRepository gives SplashPage something meaningful to read
/// instead.

@ProviderFor(firebaseStatus)
final firebaseStatusProvider = FirebaseStatusProvider._();

/// Temporary connectivity proof for Milestone 2.1 only.
///
/// This provider's only job is to confirm `Firebase.initializeApp()`
/// actually succeeded and the app is talking to the real Samvaad
/// Firebase project — not a placeholder or misconfigured one. It has
/// no role beyond this milestone and is deleted once Milestone 2.2's
/// real AuthRepository gives SplashPage something meaningful to read
/// instead.

final class FirebaseStatusProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Temporary connectivity proof for Milestone 2.1 only.
  ///
  /// This provider's only job is to confirm `Firebase.initializeApp()`
  /// actually succeeded and the app is talking to the real Samvaad
  /// Firebase project — not a placeholder or misconfigured one. It has
  /// no role beyond this milestone and is deleted once Milestone 2.2's
  /// real AuthRepository gives SplashPage something meaningful to read
  /// instead.
  FirebaseStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseStatusHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return firebaseStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$firebaseStatusHash() => r'c8423f8aa019c0cf69be8a49544d109b3f2f9a3f';
