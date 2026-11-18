// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appSession)
final appSessionProvider = AppSessionProvider._();

final class AppSessionProvider
    extends $FunctionalProvider<AppSession, AppSession, AppSession>
    with $Provider<AppSession> {
  AppSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSessionHash();

  @$internal
  @override
  $ProviderElement<AppSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppSession create(Ref ref) {
    return appSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSession>(value),
    );
  }
}

String _$appSessionHash() => r'562e236b52a7ca70f295f088d91465fe0f294bd9';
