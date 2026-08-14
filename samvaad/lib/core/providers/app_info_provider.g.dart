// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Minimal, deliberately trivial provider whose only job in Milestone 5
/// is to prove the Riverpod code-generation + DI pipeline works
/// end-to-end: `@riverpod` annotation → generated provider → consumed
/// by a widget via `ConsumerWidget`.
///
/// This is intentionally *not* a real feature. Once Auth/Chat/Calling
/// features exist, this file can be deleted — it exists only as the
/// foundation's proof-of-wiring, the DI equivalent of a "hello world."

@ProviderFor(appInfo)
final appInfoProvider = AppInfoProvider._();

/// Minimal, deliberately trivial provider whose only job in Milestone 5
/// is to prove the Riverpod code-generation + DI pipeline works
/// end-to-end: `@riverpod` annotation → generated provider → consumed
/// by a widget via `ConsumerWidget`.
///
/// This is intentionally *not* a real feature. Once Auth/Chat/Calling
/// features exist, this file can be deleted — it exists only as the
/// foundation's proof-of-wiring, the DI equivalent of a "hello world."

final class AppInfoProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Minimal, deliberately trivial provider whose only job in Milestone 5
  /// is to prove the Riverpod code-generation + DI pipeline works
  /// end-to-end: `@riverpod` annotation → generated provider → consumed
  /// by a widget via `ConsumerWidget`.
  ///
  /// This is intentionally *not* a real feature. Once Auth/Chat/Calling
  /// features exist, this file can be deleted — it exists only as the
  /// foundation's proof-of-wiring, the DI equivalent of a "hello world."
  AppInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInfoHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appInfo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appInfoHash() => r'e1fb8954da8c2adac187edf204a352a9b38a99ed';
