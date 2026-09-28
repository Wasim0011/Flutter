import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/community/presentation/controllers/groups_controller.dart';
import 'package:samvaad/features/community/presentation/providers/community_providers.dart';
import '../../fakes/fake_community_repository.dart';

void main() {
  late FakeCommunityRepository fakeRepo;
  late ProviderContainer container;

  const String userId = 'user-a';

  setUp(() {
    fakeRepo = FakeCommunityRepository();
    container = ProviderContainer(
      overrides: [communityRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() {
    fakeRepo.dispose();
    container.dispose();
  });

  test('starts in idle state', () {
    expect(container.read(createCommunityGroupControllerProvider), isA<CreateCommunityGroupIdle>());
  });

  test('fails with an empty name', () async {
    await container.read(createCommunityGroupControllerProvider.notifier).create(
      createdBy: userId,
      name: '   ',
      description: 'desc',
    );

    expect(container.read(createCommunityGroupControllerProvider), isA<CreateCommunityGroupFailed>());
  });

  test('succeeds and includes the creator as the first member', () async {
    await container.read(createCommunityGroupControllerProvider.notifier).create(
      createdBy: userId,
      name: 'Book Club',
      description: 'We read books',
    );

    final state = container.read(createCommunityGroupControllerProvider);
    expect(state, isA<CreateCommunityGroupReady>());
    final group = (state as CreateCommunityGroupReady).group;
    expect(group.memberIds, contains(userId));
    expect(group.name, 'Book Club');
  });
}