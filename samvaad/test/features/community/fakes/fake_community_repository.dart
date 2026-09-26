import 'dart:async';

import 'package:samvaad/core/error/failure.dart';
import 'package:samvaad/core/error/result.dart';
import 'package:samvaad/features/community/domain/entities/community_group.dart';
import 'package:samvaad/features/community/domain/entities/public_profile.dart';
import 'package:samvaad/features/community/domain/repositories/community_repository.dart';

class FakeCommunityRepository implements CommunityRepository {
  final Map<String, CommunityGroup> _groups = {};
  final Map<String, PublicProfile> _profiles = {};
  int _idCounter = 0;
  final StreamController<List<CommunityGroup>> _groupsController = StreamController.broadcast();

  void seedProfile(PublicProfile profile) => _profiles[profile.userId] = profile;

  void _emitGroups() => _groupsController.add(_groups.values.toList());

  @override
  Stream<List<CommunityGroup>> watchGroups() {
    return Stream<List<CommunityGroup>>.multi((controller) {
      controller.add(_groups.values.toList());
      final sub = _groupsController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<Result<CommunityGroup>> createGroup({
    required String createdBy,
    required String name,
    required String description,
  }) async {
    final String id = 'fake-group-${_idCounter++}';
    final group = CommunityGroup(
      id: id,
      name: name,
      description: description,
      createdBy: createdBy,
      memberIds: [createdBy],
      createdAt: DateTime.now(),
    );
    _groups[id] = group;
    _emitGroups();
    return Result.success(group);
  }

  @override
  Future<Result<void>> joinGroup({required String groupId, required String userId}) async {
    final existing = _groups[groupId];
    if (existing == null) return const Result.failure(Failure.unexpected('Group not found.'));
    if (!existing.memberIds.contains(userId)) {
      _groups[groupId] = CommunityGroup(
        id: existing.id,
        name: existing.name,
        description: existing.description,
        createdBy: existing.createdBy,
        memberIds: [...existing.memberIds, userId],
        createdAt: existing.createdAt,
      );
      _emitGroups();
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> leaveGroup({required String groupId, required String userId}) async {
    final existing = _groups[groupId];
    if (existing == null) return const Result.failure(Failure.unexpected('Group not found.'));
    _groups[groupId] = CommunityGroup(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      createdBy: existing.createdBy,
      memberIds: existing.memberIds.where((id) => id != userId).toList(),
      createdAt: existing.createdAt,
    );
    _emitGroups();
    return const Result.success(null);
  }

  @override
  Stream<List<PublicProfile>> watchDirectory() {
    return Stream.value(_profiles.values.toList());
  }

  @override
  Future<Result<PublicProfile?>> getPublicProfile(String userId) async {
    return Result.success(_profiles[userId]);
  }

  void dispose() => _groupsController.close();
}