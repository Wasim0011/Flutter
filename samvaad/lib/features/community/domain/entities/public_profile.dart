/// The publicly-viewable projection of a user's profile — deliberately
/// excludes phone number, which stays private to the auth feature's
/// own lookup (used only to start a chat with someone whose number
/// you already have, not to be browsed).
class PublicProfile {
  const PublicProfile({
    required this.userId,
    required this.displayName,
    this.bio,
  });

  final String userId;
  final String displayName;
  final String? bio;

  /// Two-letter initials derived from [displayName], used for the
  /// generated avatar (Milestone 5.2) — a deliberate simplification
  /// in place of photo upload, see Milestone 5.1's writeup for why.
  String get initials {
    final List<String> parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final String first = parts.first[0];
    final String second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is PublicProfile &&
              other.userId == userId &&
              other.displayName == displayName &&
              other.bio == bio);

  @override
  int get hashCode => Object.hash(userId, displayName, bio);

  @override
  String toString() => 'PublicProfile(userId: $userId, displayName: $displayName)';
}