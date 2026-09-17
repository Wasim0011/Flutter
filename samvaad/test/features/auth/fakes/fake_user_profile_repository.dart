import 'package:samvaad/core/error/result.dart';
import 'package:samvaad/features/auth/domain/entities/app_user.dart';
import 'package:samvaad/features/auth/domain/repositories/user_profile_repository.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  final Map<String, CommunicationPreference> _preferences = {};
  final Map<String, String> _phoneNumbersByUserId = {};
  final Map<String, String> _displayNames = {};

  @override
  Future<Result<void>> ensureUserDocument({
    required String userId,
    required String phoneNumber,
  }) async {
    _phoneNumbersByUserId[userId] = phoneNumber;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> saveDisplayName({
    required String userId,
    required String displayName,
  }) async {
    _displayNames[userId] = displayName;
    return const Result.success(null);
  }

  @override
  Future<Result<String?>> getDisplayName(String userId) async {
    return Result.success(_displayNames[userId]);
  }

  @override
  Future<Result<void>> saveCommunicationPreference({
    required String userId,
    required CommunicationPreference preference,
  }) async {
    _preferences[userId] = preference;
    return const Result.success(null);
  }

  @override
  Future<Result<CommunicationPreference?>> getCommunicationPreference(String userId) async {
    return Result.success(_preferences[userId]);
  }

  @override
  Future<Result<String?>> findUserIdByPhoneNumber(String phoneNumber) async {
    final entry = _phoneNumbersByUserId.entries.where((e) => e.value == phoneNumber).firstOrNull;
    return Result.success(entry?.key);
  }
}