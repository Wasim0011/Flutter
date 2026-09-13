import 'package:samvaad/core/error/result.dart';
import 'package:samvaad/features/auth/domain/entities/app_user.dart';
import 'package:samvaad/features/auth/domain/repositories/user_profile_repository.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  final Map<String, CommunicationPreference> _stored = {};

  @override
  Future<Result<void>> saveCommunicationPreference({
    required String userId,
    required CommunicationPreference preference,
  }) async {
    _stored[userId] = preference;
    return const Result.success(null);
  }

  @override
  Future<Result<CommunicationPreference?>> getCommunicationPreference(String userId) async {
    return Result.success(_stored[userId]);
  }
}