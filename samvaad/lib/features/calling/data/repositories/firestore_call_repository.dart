import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/call.dart';
import '../../domain/repositories/call_repository.dart';

class FirestoreCallRepository implements CallRepository {
  FirestoreCallRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _calls => _firestore.collection('calls');

  @override
  Future<Result<Call>> startCall({
    required String callerId,
    required List<String> calleeIds,
    String? conversationId,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final List<String> participantIds = [callerId, ...calleeIds];
      final docRef = _calls.doc();
      final String roomName = docRef.id;

      await docRef.set({
        'roomName': roomName,
        'callerId': callerId,
        'participantIds': participantIds,
        'status': CallStatus.ringing.name,
        'createdAt': Timestamp.fromDate(now),
        'conversationId': conversationId,
      });

      return Result.success(Call(
        id: docRef.id,
        roomName: roomName,
        callerId: callerId,
        participantIds: participantIds,
        status: CallStatus.ringing,
        createdAt: now,
        conversationId: conversationId,
      ));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<void>> markJoined({required String callId, required String userId}) async {
    try {
      await _calls.doc(callId).set({'status': CallStatus.active.name}, SetOptions(merge: true));
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<void>> decline({required String callId, required String userId}) async {
    try {
      await _calls.doc(callId).set({'status': CallStatus.declined.name}, SetOptions(merge: true));
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<void>> endCall(String callId) async {
    try {
      await _calls.doc(callId).set({'status': CallStatus.ended.name}, SetOptions(merge: true));
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Stream<List<Call>> watchIncomingAndActiveCalls(String userId) {
    return _calls
        .where('participantIds', arrayContains: userId)
        .where('status', whereIn: [CallStatus.ringing.name, CallStatus.active.name])
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_callFromDoc).toList());
  }

  @override
  Future<Result<String>> generateAccessToken({
    required String roomName,
    required String userId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('generateLiveKitToken');
      final result = await callable.call<Map<String, dynamic>>({'roomName': roomName});
      final String? token = result.data['token'] as String?;
      if (token == null) {
        return const Result.failure(Failure.unexpected('No token returned.'));
      }
      return Result.success(token);
    } on FirebaseFunctionsException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  Call _callFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Call(
      id: doc.id,
      roomName: data['roomName'] as String,
      callerId: data['callerId'] as String,
      participantIds: List<String>.from(data['participantIds'] as List),
      status: CallStatus.values.firstWhere((s) => s.name == data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      conversationId: data['conversationId'] as String?,
    );
  }
}