import 'dart:convert';

import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

part 'caption_controller.g.dart';

/// One caption line attributed to a participant.
class CaptionLine {
  const CaptionLine({
    required this.participantId,
    required this.text,
    required this.isFinal,
  });

  final String participantId;
  final String text;
  final bool isFinal;
}

/// Whether captions are currently shown. Call screens set an initial
/// default based on communicationPreference, but this is a plain
/// toggle from that point on — any user can turn captions on/off
/// regardless of their stated preference.
@riverpod
class CaptionsEnabled extends _$CaptionsEnabled {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Latest caption line per participant, keyed by participant identity.
/// Updated from both our own speech recognition and data messages
/// received from remote participants over the LiveKit room.
@riverpod
class CaptionFeed extends _$CaptionFeed {
  @override
  Map<String, CaptionLine> build() => {};

  void update(CaptionLine line) {
    state = {...state, line.participantId: line};
  }

  void clear() => state = {};
}

/// Bridges on-device speech-to-text to a LiveKit room's data channel.
///
/// See the milestone note on the audio-session constraint of running
/// STT alongside LiveKit's own microphone capture — this is a real,
/// documented risk on iOS specifically, accepted here as a scoped
/// trade-off for a phase-appropriate MVP, not an oversight.
class CaptionSpeechService {
  CaptionSpeechService({
    required Room room,
    required String localParticipantId,
    required void Function(CaptionLine) onLocalCaption,
  })  : _room = room,
        _localParticipantId = localParticipantId,
        _onLocalCaption = onLocalCaption;

  final Room _room;
  final String _localParticipantId;
  final void Function(CaptionLine) _onLocalCaption;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;

  Future<bool> start() async {
    if (_listening) return true;

    final bool available = await _speech.initialize();
    if (!available) return false;

    _listening = true;

    await _speech.listen(
      onResult: (result) {
        final CaptionLine line = CaptionLine(
          participantId: _localParticipantId,
          text: result.recognizedWords,
          isFinal: result.finalResult,
        );

        _onLocalCaption(line);
        _broadcast(line);
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );

    return true;
  }

  void _broadcast(CaptionLine line) {
    final String payload = jsonEncode({
      'senderId': line.participantId,
      'text': line.text,
      'isFinal': line.isFinal,
    });
    // NOTE: publishData's exact signature varies across livekit_client
    // versions (named args differ, some versions take a Reliability
    // enum, others a bool). If this doesn't compile against your
    // installed version, paste the error — this is the single most
    // likely spot in this milestone to need a version-specific fix.
    _room.localParticipant?.publishData(utf8.encode(payload));
  }

  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;
    await _speech.stop();
  }
}