import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/community_group.dart';
import '../providers/community_providers.dart';

part 'groups_controller.g.dart';

@riverpod
Stream<List<CommunityGroup>> groups(Ref ref) {
  return ref.watch(communityRepositoryProvider).watchGroups();
}

sealed class CreateCommunityGroupState {
  const CreateCommunityGroupState();
}

final class CreateCommunityGroupIdle extends CreateCommunityGroupState {
  const CreateCommunityGroupIdle();
}

final class CreateCommunityGroupSubmitting extends CreateCommunityGroupState {
  const CreateCommunityGroupSubmitting();
}

final class CreateCommunityGroupFailed extends CreateCommunityGroupState {
  const CreateCommunityGroupFailed(this.message);
  final String message;
}

final class CreateCommunityGroupReady extends CreateCommunityGroupState {
  const CreateCommunityGroupReady(this.group);
  final CommunityGroup group;
}

@riverpod
class CreateCommunityGroupController extends _$CreateCommunityGroupController {
  @override
  CreateCommunityGroupState build() => const CreateCommunityGroupIdle();

  Future<void> create({
    required String createdBy,
    required String name,
    required String description,
  }) async {
    if (name.trim().isEmpty) {
      state = const CreateCommunityGroupFailed('Give the group a name.');
      return;
    }

    state = const CreateCommunityGroupSubmitting();

    final result = await ref
        .read(communityRepositoryProvider)
        .createGroup(
          createdBy: createdBy,
          name: name.trim(),
          description: description.trim(),
        );

    state = result.fold(
      onSuccess: (group) => CreateCommunityGroupReady(group),
      onFailure: (failure) => CreateCommunityGroupFailed(failure.message),
    );
  }

  void reset() => state = const CreateCommunityGroupIdle();
}
