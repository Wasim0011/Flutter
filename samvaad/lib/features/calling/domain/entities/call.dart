/// A call session — either an active room to join, or a pending
/// invitation waiting to be accepted/declined.
///
/// Deliberately mirrors Conversation's shape (id, participantIds,
/// isGroup derivation) since calling and chat are conceptually
/// siblings — both are "a set of people communicating" — but this
/// entity has no dependency on Conversation; a call can exist for a
/// conversation that already has messages, or be started fresh.
class Call {
  const Call({
    required this.id,
    required this.roomName,
    required this.callerId,
    required this.participantIds,
    required this.status,
    required this.createdAt,
    this.conversationId,
  });

  final String id;

  /// The LiveKit room name this call maps to. Kept distinct from [id]
  /// deliberately — [id] is our own Firestore document id (used for
  /// signaling/ringing state), [roomName] is what we hand to the
  /// LiveKit SDK. They could theoretically diverge (e.g. token
  /// refresh needing a stable room name across reconnects) even
  /// though today they're set equal at creation.
  final String roomName;

  final String callerId;
  final List<String> participantIds;
  final CallStatus status;
  final DateTime createdAt;

  /// If this call originated from an existing chat conversation,
  /// its id — lets the call screen link back to that conversation's
  /// context (participant names already known, etc). Null for calls
  /// started without a prior conversation (not built yet, but the
  /// field costs nothing to allow now).
  final String? conversationId;

  bool get isGroup => participantIds.length > 2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Call &&
              other.id == id &&
              other.roomName == roomName &&
              other.callerId == callerId &&
              _listEquals(other.participantIds, participantIds) &&
              other.status == status &&
              other.createdAt == createdAt &&
              other.conversationId == conversationId);

  @override
  int get hashCode => Object.hash(
    id,
    roomName,
    callerId,
    Object.hashAll(participantIds),
    status,
    createdAt,
    conversationId,
  );

  @override
  String toString() => 'Call(id: $id, status: $status, participantIds: $participantIds)';
}

enum CallStatus {
  /// Signaled but not yet answered by any callee.
  ringing,

  /// At least one callee has joined the LiveKit room.
  active,

  /// Ended normally (hangup) or all parties left.
  ended,

  /// A callee explicitly declined before joining.
  declined,

  /// Rang without answer for too long.
  missed,
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}