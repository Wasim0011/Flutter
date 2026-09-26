import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

abstract interface class UserProfileRepository {
  Future<Result<void>> ensureUserDocument({
    required String userId,
    required String phoneNumber,
  });

  /// Saves the user-chosen display name, collected during onboarding.
  /// Chat (Milestone 3.5) uses this to show real names in conversation
  /// lists and titles instead of raw user ids.
  Future<Result<void>> saveDisplayName({
    required String userId,
    required String displayName,
  });

  /// Returns the stored display name for [userId], or null if not set.
  Future<Result<String?>> getDisplayName(String userId);

  Future<Result<void>> saveCommunicationPreference({
    required String userId,
    required CommunicationPreference preference,
  });

  Future<Result<CommunicationPreference?>> getCommunicationPreference(String userId);

  Future<Result<String?>> findUserIdByPhoneNumber(String phoneNumber);

  /// Saves a short, user-written bio, shown on their public profile
  /// (Milestone 5.2). Optional — a user may never set one.
  Future<Result<void>> saveBio({required String userId, required String bio});

  /// Returns the stored bio for [userId], or null if not set.
  Future<Result<String?>> getBio(String userId);
}