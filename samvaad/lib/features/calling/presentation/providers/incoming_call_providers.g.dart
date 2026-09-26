// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_call_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The most recent call ringing *for* [userId] that they didn't
/// initiate themselves — null if there's no such call right now.
///
/// Filters out calls the user started (callerId == userId) since a
/// caller shouldn't see their own outgoing call rendered as an
/// "incoming call" screen — that's CallPage's job once they're
/// already connected.

@ProviderFor(nextIncomingCall)
final nextIncomingCallProvider = NextIncomingCallFamily._();

/// The most recent call ringing *for* [userId] that they didn't
/// initiate themselves — null if there's no such call right now.
///
/// Filters out calls the user started (callerId == userId) since a
/// caller shouldn't see their own outgoing call rendered as an
/// "incoming call" screen — that's CallPage's job once they're
/// already connected.

final class NextIncomingCallProvider
    extends $FunctionalProvider<AsyncValue<Call?>, Call?, Stream<Call?>>
    with $FutureModifier<Call?>, $StreamProvider<Call?> {
  /// The most recent call ringing *for* [userId] that they didn't
  /// initiate themselves — null if there's no such call right now.
  ///
  /// Filters out calls the user started (callerId == userId) since a
  /// caller shouldn't see their own outgoing call rendered as an
  /// "incoming call" screen — that's CallPage's job once they're
  /// already connected.
  NextIncomingCallProvider._({
    required NextIncomingCallFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'nextIncomingCallProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextIncomingCallHash();

  @override
  String toString() {
    return r'nextIncomingCallProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Call?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Call?> create(Ref ref) {
    final argument = this.argument as String;
    return nextIncomingCall(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NextIncomingCallProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextIncomingCallHash() => r'9740c86d37e655417a8f299e2bb1af37240b7586';

/// The most recent call ringing *for* [userId] that they didn't
/// initiate themselves — null if there's no such call right now.
///
/// Filters out calls the user started (callerId == userId) since a
/// caller shouldn't see their own outgoing call rendered as an
/// "incoming call" screen — that's CallPage's job once they're
/// already connected.

final class NextIncomingCallFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Call?>, String> {
  NextIncomingCallFamily._()
    : super(
        retry: null,
        name: r'nextIncomingCallProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The most recent call ringing *for* [userId] that they didn't
  /// initiate themselves — null if there's no such call right now.
  ///
  /// Filters out calls the user started (callerId == userId) since a
  /// caller shouldn't see their own outgoing call rendered as an
  /// "incoming call" screen — that's CallPage's job once they're
  /// already connected.

  NextIncomingCallProvider call(String userId) =>
      NextIncomingCallProvider._(argument: userId, from: this);

  @override
  String toString() => r'nextIncomingCallProvider';
}
