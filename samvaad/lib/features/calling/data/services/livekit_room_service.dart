import 'package:livekit_client/livekit_client.dart';

/// Thin wrapper around a LiveKit [Room] connection.
///
/// This is the one file that owns direct LiveKit SDK usage —
/// everything above it (controllers, screens) works against this
/// service's narrow surface, not the SDK directly. If the transport
/// were ever swapped (self-hosted LiveKit, or a different provider
/// entirely), this is the only file that would need to change.
class LiveKitRoomService {
  Room? _room;
  Room get room => _room ?? (throw StateError('Not connected — call connect() first.'));

  bool get isConnected => _room != null;

  Future<void> connect({required String url, required String token}) async {
    final Room room = Room();
    await room.connect(url, token);
    await room.localParticipant?.setCameraEnabled(true);
    await room.localParticipant?.setMicrophoneEnabled(true);
    _room = room;
  }

  Future<void> setCameraEnabled(bool enabled) async {
    await _room?.localParticipant?.setCameraEnabled(enabled);
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
  }
}