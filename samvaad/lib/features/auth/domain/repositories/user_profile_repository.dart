import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

/// Persists and retrieves the parts of a user's profile that live
/// beyond Firebase Auth itself.
abstract interface class UserProfileRepository {
  /// Ensures a Firestore document exists for [userId] containing at
  /// least [phoneNumber]. Called once right after sign-in, regardless
  /// of onboarding status — chat needs to find users by phone number,
  /// which requires this to exist before onboarding necessarily
  /// completes (a user could sign in, get interrupted, and someone
  /// else might still want to find them by phone in the meantime).
  Future<Result<void>> ensureUserDocument({
    required String userId,
    required String phoneNumber,
  });

  Future<Result<void>> saveCommunicationPreference({
    required String userId,
    required CommunicationPreference preference,
  });

  Future<Result<CommunicationPreference?>> getCommunicationPreference(String userId);

  /// Finds the user id whose stored phone number matches
  /// [phoneNumber], or null if no such user exists. [phoneNumber]
  /// must be E.164-formatted, same convention as everywhere else in
  /// the auth feature.
  Future<Result<String?>> findUserIdByPhoneNumber(String phoneNumber);
}