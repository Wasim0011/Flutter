import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Firestore implementation of [UserProfileRepository].
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  @override
  Future<Result<void>> ensureUserDocument({
    required String userId,
    required String phoneNumber,
  }) async {
    try {
      await _users.doc(userId).set(
        {'phoneNumber': phoneNumber},
        SetOptions(merge: true),
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

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

      final CommunicationPreference? preference =
          CommunicationPreference.values.where((p) => p.name == raw).firstOrNull;
      return Result.success(preference);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<String?>> findUserIdByPhoneNumber(String phoneNumber) async {
    try {
      final query = await _users.where('phoneNumber', isEqualTo: phoneNumber).limit(1).get();
      if (query.docs.isEmpty) return const Result.success(null);
      return Result.success(query.docs.first.id);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }
}