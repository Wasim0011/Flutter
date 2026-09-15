// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_group_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateGroupController)
final createGroupControllerProvider = CreateGroupControllerProvider._();

final class CreateGroupControllerProvider
    extends $NotifierProvider<CreateGroupController, CreateGroupState> {
  CreateGroupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createGroupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createGroupControllerHash();

  @$internal
  @override
  CreateGroupController create() => CreateGroupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateGroupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateGroupState>(value),
    );
  }
}

String _$createGroupControllerHash() =>
    r'2b5f00205fdb06f5251841ae992386cea6516ed2';

abstract class _$CreateGroupController extends $Notifier<CreateGroupState> {
  CreateGroupState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CreateGroupState, CreateGroupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreateGroupState, CreateGroupState>,
              CreateGroupState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
