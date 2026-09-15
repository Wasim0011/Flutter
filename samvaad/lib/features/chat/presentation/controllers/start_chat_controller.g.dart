// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StartChatController)
final startChatControllerProvider = StartChatControllerProvider._();

final class StartChatControllerProvider
    extends $NotifierProvider<StartChatController, StartChatState> {
  StartChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startChatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startChatControllerHash();

  @$internal
  @override
  StartChatController create() => StartChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartChatState>(value),
    );
  }
}

String _$startChatControllerHash() =>
    r'c024d15990b12ad36b8e46f4f3ee66306600707f';

abstract class _$StartChatController extends $Notifier<StartChatState> {
  StartChatState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StartChatState, StartChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StartChatState, StartChatState>,
              StartChatState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
