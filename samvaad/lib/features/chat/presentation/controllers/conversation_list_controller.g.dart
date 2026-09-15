// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live stream of the current user's conversations. A StreamProvider
/// family keyed by userId — Riverpod handles subscription lifecycle
/// (cancels the Firestore listener automatically once nothing watches
/// this anymore).

@ProviderFor(conversationList)
final conversationListProvider = ConversationListFamily._();

/// Live stream of the current user's conversations. A StreamProvider
/// family keyed by userId — Riverpod handles subscription lifecycle
/// (cancels the Firestore listener automatically once nothing watches
/// this anymore).

final class ConversationListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Conversation>>,
          List<Conversation>,
          Stream<List<Conversation>>
        >
    with
        $FutureModifier<List<Conversation>>,
        $StreamProvider<List<Conversation>> {
  /// Live stream of the current user's conversations. A StreamProvider
  /// family keyed by userId — Riverpod handles subscription lifecycle
  /// (cancels the Firestore listener automatically once nothing watches
  /// this anymore).
  ConversationListProvider._({
    required ConversationListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationListHash();

  @override
  String toString() {
    return r'conversationListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Conversation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Conversation>> create(Ref ref) {
    final argument = this.argument as String;
    return conversationList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationListHash() => r'287193bf30b453176317dda8054874731cd17a6c';

/// Live stream of the current user's conversations. A StreamProvider
/// family keyed by userId — Riverpod handles subscription lifecycle
/// (cancels the Firestore listener automatically once nothing watches
/// this anymore).

final class ConversationListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Conversation>>, String> {
  ConversationListFamily._()
    : super(
        retry: null,
        name: r'conversationListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live stream of the current user's conversations. A StreamProvider
  /// family keyed by userId — Riverpod handles subscription lifecycle
  /// (cancels the Firestore listener automatically once nothing watches
  /// this anymore).

  ConversationListProvider call(String userId) =>
      ConversationListProvider._(argument: userId, from: this);

  @override
  String toString() => r'conversationListProvider';
}
