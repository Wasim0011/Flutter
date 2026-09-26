/// A public, joinable interest-based group — distinct from a chat
/// Conversation. A group can exist (be browsed, joined) without any
/// messages ever being sent in it; joining a CommunityGroup and
/// starting a chat Conversation are two separate actions, deliberately
/// not fused into one entity (a chat Conversation's `type: group` is
/// about who's in a conversation, this is about community membership).
class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;

  int get memberCount => memberIds.length;

  bool isMember(String userId) => memberIds.contains(userId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is CommunityGroup &&
              other.id == id &&
              other.name == name &&
              other.description == description &&
              other.createdBy == createdBy &&
              _listEquals(other.memberIds, memberIds) &&
              other.createdAt == createdAt);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    createdBy,
    Object.hashAll(memberIds),
    createdAt,
  );

  @override
  String toString() => 'CommunityGroup(id: $id, name: $name, memberCount: $memberCount)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}