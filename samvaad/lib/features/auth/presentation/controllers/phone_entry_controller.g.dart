// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_entry_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PhoneEntryController)
final phoneEntryControllerProvider = PhoneEntryControllerProvider._();

final class PhoneEntryControllerProvider
    extends $NotifierProvider<PhoneEntryController, PhoneEntryState> {
  PhoneEntryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneEntryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneEntryControllerHash();

  @$internal
  @override
  PhoneEntryController create() => PhoneEntryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneEntryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneEntryState>(value),
    );
  }
}

String _$phoneEntryControllerHash() =>
    r'e4121d8236567556ddf786912c3c30e9b7f0e55c';

abstract class _$PhoneEntryController extends $Notifier<PhoneEntryState> {
  PhoneEntryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneEntryState, PhoneEntryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PhoneEntryState, PhoneEntryState>,
              PhoneEntryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
