import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/public_profile.dart';
import '../providers/community_providers.dart';

part 'directory_controller.g.dart';

@riverpod
Stream<List<PublicProfile>> directory(Ref ref) {
  return ref.watch(communityRepositoryProvider).watchDirectory();
}

@riverpod
Future<PublicProfile?> publicProfile(Ref ref, String userId) {
  return ref.read(communityRepositoryProvider).getPublicProfile(userId).then(
        (result) => result.fold(onSuccess: (profile) => profile, onFailure: (_) => null),
  );
}