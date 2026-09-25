import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/livekit_room_service.dart';
import '../../domain/entities/call.dart';
import '../providers/call_providers.dart';

part 'call_session_controller.g.dart';

/// LiveKit Cloud project URL. Not a secret (unlike the API key/secret,
/// which never leave the Cloud Function) — safe to keep as a constant
/// here, same treatment as a Firebase project id.
const String liveKitUrl = 'wss://REPLACE-WITH-YOUR-PROJECT.livekit.cloud';

sealed class CallSessionState {
  const CallSessionState();
}

final class CallSessionIdle extends CallSessionState {
  const CallSessionIdle();
}

final class CallSessionConnecting extends CallSessionState {
  const CallSessionConnecting();
}

final class CallSessionFailed extends CallSessionState {
  const CallSessionFailed(this.message);
  final String message;
}

final class CallSessionConnected extends CallSessionState {
  const CallSessionConnected(this.room);
  final Room room;
}

@riverpod
class CallSessionController extends _$CallSessionController {
  final LiveKitRoomService _service = LiveKitRoomService();

  @override
  CallSessionState build() {
    ref.onDispose(() {
      _service.disconnect();
    });
    return const CallSessionIdle();
  }

  Future<void> join({required String callId, required Call call, required String userId}) async {
    state = const CallSessionConnecting();

    final tokenResult = await ref
        .read(callRepositoryProvider)
        .generateAccessToken(roomName: call.roomName, userId: userId);

    if (tokenResult.isFailure) {
      state = CallSessionFailed(
        tokenResult.fold(onSuccess: (_) => '', onFailure: (f) => f.message),
      );
      return;
    }

    final String token = tokenResult.fold(onSuccess: (t) => t, onFailure: (_) => '');

    try {
      await _service.connect(url: liveKitUrl, token: token);
      await ref.read(callRepositoryProvider).markJoined(callId: callId, userId: userId);
      state = CallSessionConnected(_service.room);
    } catch (e) {
      state = CallSessionFailed(e.toString());
    }
  }

  Future<void> toggleCamera(bool enabled) => _service.setCameraEnabled(enabled);
  Future<void> toggleMicrophone(bool enabled) => _service.setMicrophoneEnabled(enabled);

  Future<void> leave(String callId) async {
    await _service.disconnect();
    await ref.read(callRepositoryProvider).endCall(callId);
    state = const CallSessionIdle();
  }
}