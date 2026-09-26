import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/community_group.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/community_repository.dart';

class FirestoreCommunityRepository implements CommunityRepository {
  FirestoreCommunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _groups => _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  @override
  Stream<List<CommunityGroup>> watchGroups() {
    return _groups
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_groupFromDoc).toList());
  }

  @override
  Future<Result<CommunityGroup>> createGroup({
    required String createdBy,
    required String name,
    required String description,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final docRef = await _groups.add({
        'name': name,
        'description': description,
        'createdBy': createdBy,
        'memberIds': [createdBy],
        'createdAt': Timestamp.fromDate(now),
      });

      return Result.success(CommunityGroup(
        id: docRef.id,
        name: name,
        description: description,
        createdBy: createdBy,
        memberIds: [createdBy],
        createdAt: now,
      ));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<void>> joinGroup({required String groupId, required String userId}) async {
    try {
      await _groups.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<void>> leaveGroup({required String groupId, required String userId}) async {
    try {
      await _groups.doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Stream<List<PublicProfile>> watchDirectory() {
    return _users.snapshots().map(
          (snapshot) => snapshot.docs
          .where((doc) => (doc.data()['displayName'] as String?)?.isNotEmpty ?? false)
          .map(_profileFromDoc)
          .toList(),
    );
  }

  @override
  Future<Result<PublicProfile?>> getPublicProfile(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return const Result.success(null);
      final String? name = doc.data()?['displayName'] as String?;
      if (name == null) return const Result.success(null);
      return Result.success(_profileFromDoc(doc));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  CommunityGroup _groupFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CommunityGroup(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      createdBy: data['createdBy'] as String,
      memberIds: List<String>.from(data['memberIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  PublicProfile _profileFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PublicProfile(
      userId: doc.id,
      displayName: data['displayName'] as String,
      bio: data['bio'] as String?,
    );
  }
}