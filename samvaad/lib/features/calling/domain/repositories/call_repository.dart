import '../../../../core/error/result.dart';
import '../entities/call.dart';

/// Contract for call signaling and lifecycle. Notably, this interface
/// does NOT expose anything about actually joining/rendering video —
/// that's the job of a separate `VideoSessionRepository` (or similar,
/// introduced in Milestone 4.3) which wraps the LiveKit SDK's room
/// connection directly. This interface is deliberately scoped to
/// signaling: who's calling whom, ringing/accepted/declined state,
/// stored in Firestore so all parties see consistent call state
/// without needing an active LiveKit connection just to know a call
/// exists.
abstract interface class CallRepository {
  /// Initiates a call: creates a Firestore-backed [Call] in
  /// [CallStatus.ringing], with [callerId] as the first participant.
  Future<Result<Call>> startCall({
    required String callerId,
    required List<String> calleeIds,
    String? conversationId,
  });

  /// Marks [callId] as [CallStatus.active] once [userId] joins the
  /// actual LiveKit room.
  Future<Result<void>> markJoined({required String callId, required String userId});

  /// Marks [callId] as [CallStatus.declined] by [userId].
  Future<Result<void>> decline({required String callId, required String userId});

  /// Ends [callId] entirely (any participant can end a call for
  /// everyone — consistent with how most calling apps behave).
  Future<Result<void>> endCall(String callId);

  /// Live stream of calls where [userId] is a participant and the
  /// call is still ringing or active — used to detect and surface
  /// incoming calls in real time.
  Stream<List<Call>> watchIncomingAndActiveCalls(String userId);

  /// Generates a LiveKit access token for [userId] to join
  /// [roomName]. This is the one method that will need a backend
  /// (Cloud Function) behind it in Milestone 4.2, since token
  /// generation requires the LiveKit API secret, which must never
  /// live in the client.
  Future<Result<String>> generateAccessToken({
    required String roomName,
    required String userId,
  });
}