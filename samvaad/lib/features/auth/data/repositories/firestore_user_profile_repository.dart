import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Firestore implementation of [UserProfileRepository].
///
/// This is the only file that should import `cloud_firestore` for
/// profile data — same discipline as FirebaseAuthRepository being the
/// sole `firebase_auth` importer.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  @override
  Future<Result<void>> saveCommunicationPreference({
    required String userId,
    required CommunicationPreference preference,
  }) async {
    try {
      await _users.doc(userId).set(
        {'communicationPreference': preference.name},
        SetOptions(merge: true),
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<CommunicationPreference?>> getCommunicationPreference(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      final String? raw = doc.data()?['communicationPreference'] as String?;
      if (raw == null) return const Result.success(null);

      final CommunicationPreference? preference = CommunicationPreference.values
          .where((p) => p.name == raw)
          .firstOrNull;
      return Result.success(preference);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }
}