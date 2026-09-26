import '../../../../core/error/result.dart';
import '../entities/community_group.dart';
import '../entities/public_profile.dart';

abstract interface class CommunityRepository {
  /// Live list of all public groups, newest first.
  Stream<List<CommunityGroup>> watchGroups();

  Future<Result<CommunityGroup>> createGroup({
    required String createdBy,
    required String name,
    required String description,
  });

  Future<Result<void>> joinGroup({required String groupId, required String userId});

  Future<Result<void>> leaveGroup({required String groupId, required String userId});

  /// Live list of all users' public profiles — the directory. Returns
  /// [PublicProfile], never raw [AppUser]/phone data.
  Stream<List<PublicProfile>> watchDirectory();

  /// One user's public profile, or null if not found.
  Future<Result<PublicProfile?>> getPublicProfile(String userId);
}