import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

/// Persists and retrieves the parts of a user's profile that live
/// beyond Firebase Auth itself — currently just communication
/// preference, but this is the natural home for future profile fields
/// (avatar, bio, community info) without touching AuthRepository.
abstract interface class UserProfileRepository {
  /// Saves [preference] for the user identified by [userId].
  Future<Result<void>> saveCommunicationPreference({
    required String userId,
    required CommunicationPreference preference,
  });

  /// Fetches the stored communication preference for [userId], or
  /// null if the user hasn't completed onboarding yet.
  Future<Result<CommunicationPreference?>> getCommunicationPreference(String userId);
}