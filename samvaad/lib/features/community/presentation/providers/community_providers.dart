import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/firestore_community_repository.dart';
import '../../domain/repositories/community_repository.dart';

part 'community_providers.g.dart';

@riverpod
CommunityRepository communityRepository(Ref ref) {
  return FirestoreCommunityRepository();
}