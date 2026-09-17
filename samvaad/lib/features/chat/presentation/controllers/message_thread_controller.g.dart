// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_thread_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live stream of messages for one conversation.

@ProviderFor(messageThread)
final messageThreadProvider = MessageThreadFamily._();

/// Live stream of messages for one conversation.

final class MessageThreadProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Message>>,
          List<Message>,
          Stream<List<Message>>
        >
    with $FutureModifier<List<Message>>, $StreamProvider<List<Message>> {
  /// Live stream of messages for one conversation.
  MessageThreadProvider._({
    required MessageThreadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageThreadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageThreadHash();

  @override
  String toString() {
    return r'messageThreadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Message>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Message>> create(Ref ref) {
    final argument = this.argument as String;
    return messageThread(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageThreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageThreadHash() => r'bebfa0ee9bc030dddb43df3f016afbf391c3ec94';

/// Live stream of messages for one conversation.

final class MessageThreadFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Message>>, String> {
  MessageThreadFamily._()
    : super(
        retry: null,
        name: r'messageThreadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live stream of messages for one conversation.

  MessageThreadProvider call(String conversationId) =>
      MessageThreadProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'messageThreadProvider';
}

@ProviderFor(SendMessageController)
final sendMessageControllerProvider = SendMessageControllerProvider._();

final class SendMessageControllerProvider
    extends $NotifierProvider<SendMessageController, SendMessageState> {
  SendMessageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendMessageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendMessageControllerHash();

  @$internal
  @override
  SendMessageController create() => SendMessageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendMessageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendMessageState>(value),
    );
  }
}

String _$sendMessageControllerHash() =>
    r'1fac4b27a9cdf5f667ddb1f1154648349eb3b645';

abstract class _$SendMessageController extends $Notifier<SendMessageState> {
  SendMessageState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SendMessageState, SendMessageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SendMessageState, SendMessageState>,
              SendMessageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
