/// A conversation between two or more users — either a direct (1:1)
/// exchange or a named group.
///
/// `title` is nullable and only meaningful for groups; direct
/// conversations derive their display name from the other participant
/// at the presentation layer (this entity doesn't know about display
/// names — that's `AppUser`'s job, kept out of this feature to avoid
/// a circular dependency between chat and auth).
///
/// `lastMessagePreview`/`lastMessageAt` are deliberately denormalized
/// onto the conversation itself rather than requiring a separate query
/// per conversation to show a list preview — a common, deliberate
/// Firestore modeling choice for exactly this "list of chats" use case.
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.createdAt,
    this.title,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final DateTime createdAt;
  final String? title;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;

  bool get isGroup => type == ConversationType.group;

  /// For a direct conversation, returns the participant id that isn't
  /// [currentUserId]. Returns null for groups, or if [currentUserId]
  /// isn't actually a participant (a defensive case that shouldn't
  /// happen in practice, but this entity has no way to enforce it).
  String? otherParticipantId(String currentUserId) {
    if (isGroup) return null;
    return participantIds.where((id) => id != currentUserId).firstOrNull;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Conversation &&
              other.id == id &&
              other.type == type &&
              _listEquals(other.participantIds, participantIds) &&
              other.createdAt == createdAt &&
              other.title == title &&
              other.lastMessagePreview == lastMessagePreview &&
              other.lastMessageAt == lastMessageAt);

  @override
  int get hashCode => Object.hash(
    id,
    type,
    Object.hashAll(participantIds),
    createdAt,
    title,
    lastMessagePreview,
    lastMessageAt,
  );

  @override
  String toString() =>
      'Conversation(id: $id, type: $type, participantIds: $participantIds, title: $title)';
}

enum ConversationType { direct, group }

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}