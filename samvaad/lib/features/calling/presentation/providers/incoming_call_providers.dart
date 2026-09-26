import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/call.dart';
import '../providers/call_providers.dart';

part 'incoming_call_providers.g.dart';

/// The most recent call ringing *for* [userId] that they didn't
/// initiate themselves — null if there's no such call right now.
///
/// Filters out calls the user started (callerId == userId) since a
/// caller shouldn't see their own outgoing call rendered as an
/// "incoming call" screen — that's CallPage's job once they're
/// already connected.
@riverpod
Stream<Call?> nextIncomingCall(Ref ref, String userId) {
  return ref.watch(callRepositoryProvider).watchIncomingAndActiveCalls(userId).map((calls) {
    final List<Call> ringingForMe =
    calls.where((c) => c.status == CallStatus.ringing && c.callerId != userId).toList();
    return ringingForMe.isEmpty ? null : ringingForMe.first;
  });
}