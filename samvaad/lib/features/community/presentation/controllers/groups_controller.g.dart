// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(groups)
final groupsProvider = GroupsProvider._();

final class GroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CommunityGroup>>,
          List<CommunityGroup>,
          Stream<List<CommunityGroup>>
        >
    with
        $FutureModifier<List<CommunityGroup>>,
        $StreamProvider<List<CommunityGroup>> {
  GroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupsHash();

  @$internal
  @override
  $StreamProviderElement<List<CommunityGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CommunityGroup>> create(Ref ref) {
    return groups(ref);
  }
}

String _$groupsHash() => r'665be8035e0e87802e7c4d77d03c4efa004accd1';

@ProviderFor(CreateCommunityGroupController)
final createCommunityGroupControllerProvider =
    CreateCommunityGroupControllerProvider._();

final class CreateCommunityGroupControllerProvider
    extends
        $NotifierProvider<
          CreateCommunityGroupController,
          CreateCommunityGroupState
        > {
  CreateCommunityGroupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createCommunityGroupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createCommunityGroupControllerHash();

  @$internal
  @override
  CreateCommunityGroupController create() => CreateCommunityGroupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateCommunityGroupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateCommunityGroupState>(value),
    );
  }
}

String _$createCommunityGroupControllerHash() =>
    r'9b6d29a401f6903789af5b39482c9b27c70da847';

abstract class _$CreateCommunityGroupController
    extends $Notifier<CreateCommunityGroupState> {
  CreateCommunityGroupState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CreateCommunityGroupState, CreateCommunityGroupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreateCommunityGroupState, CreateCommunityGroupState>,
              CreateCommunityGroupState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
