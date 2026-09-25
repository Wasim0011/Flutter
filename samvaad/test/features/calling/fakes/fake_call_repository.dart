import 'dart:async';

import 'package:samvaad/core/error/failure.dart';
import 'package:samvaad/core/error/result.dart';
import 'package:samvaad/features/calling/domain/entities/call.dart';
import 'package:samvaad/features/calling/domain/repositories/call_repository.dart';

class FakeCallRepository implements CallRepository {
  final Map<String, Call> _calls = {};
  int _idCounter = 0;
  final StreamController<List<Call>> _controller = StreamController.broadcast();

  /// Set to force generateAccessToken to fail, for testing error paths.
  bool tokenGenerationShouldFail = false;

  void _emit() => _controller.add(_calls.values.toList());

  @override
  Future<Result<Call>> startCall({
    required String callerId,
    required List<String> calleeIds,
    String? conversationId,
  }) async {
    final String id = 'fake-call-${_idCounter++}';
    final call = Call(
      id: id,
      roomName: id,
      callerId: callerId,
      participantIds: [callerId, ...calleeIds],
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
      conversationId: conversationId,
    );
    _calls[id] = call;
    _emit();
    return Result.success(call);
  }

  Call _withStatus(String callId, CallStatus status) {
    final existing = _calls[callId]!;
    return Call(
      id: existing.id,
      roomName: existing.roomName,
      callerId: existing.callerId,
      participantIds: existing.participantIds,
      status: status,
      createdAt: existing.createdAt,
      conversationId: existing.conversationId,
    );
  }

  @override
  Future<Result<void>> markJoined({required String callId, required String userId}) async {
    _calls[callId] = _withStatus(callId, CallStatus.active);
    _emit();
    return const Result.success(null);
  }

  @override
  Future<Result<void>> decline({required String callId, required String userId}) async {
    _calls[callId] = _withStatus(callId, CallStatus.declined);
    _emit();
    return const Result.success(null);
  }

  @override
  Future<Result<void>> endCall(String callId) async {
    _calls[callId] = _withStatus(callId, CallStatus.ended);
    _emit();
    return const Result.success(null);
  }

  @override
  Stream<List<Call>> watchIncomingAndActiveCalls(String userId) {
    return Stream<List<Call>>.multi((controller) {
      controller.add(_currentFor(userId));
      final sub = _controller.stream.listen((_) => controller.add(_currentFor(userId)));
      controller.onCancel = sub.cancel;
    });
  }

  List<Call> _currentFor(String userId) => _calls.values
      .where((c) =>
  c.participantIds.contains(userId) &&
      (c.status == CallStatus.ringing || c.status == CallStatus.active))
      .toList();

  @override
  Future<Result<String>> generateAccessToken({
    required String roomName,
    required String userId,
  }) async {
    if (tokenGenerationShouldFail) {
      return const Result.failure(Failure.unexpected('Token generation failed.'));
    }
    return Result.success('fake-token-for-$userId-in-$roomName');
  }

  void dispose() => _controller.close();
}