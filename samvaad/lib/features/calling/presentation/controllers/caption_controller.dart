import 'dart:convert';

import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'dart:async';
import 'dart:typed_data';
import '../../../translation/domain/repositories/sign_interpretation_repository.dart';

part 'caption_controller.g.dart';

/// Periodically asks [SignInterpretationRepository] to interpret the
/// local camera feed as sign language, surfacing results through the
/// same caption feed speech captions use.
///
/// Deliberately polls every few seconds rather than every frame — each
/// call is a real network request to Gemini, and continuous per-frame
/// requests would be both expensive and unnecessary given a single
/// frame can't capture a gesture's motion anyway (see Milestone 6.1's
/// documented limitation). This is a best-effort assist, not
/// continuous translation, and its pacing reflects that honestly.
class SignFrameCaptureService {
  SignFrameCaptureService({
    required SignInterpretationRepository repository,
    required String localParticipantId,
    required void Function(CaptionLine) onInterpretation,
    required Future<Uint8List?> Function() captureFrame,
  }) : _repository = repository,
       _localParticipantId = localParticipantId,
       _onInterpretation = onInterpretation,
       _captureFrame = captureFrame;

  final SignInterpretationRepository _repository;
  final String _localParticipantId;
  final void Function(CaptionLine) _onInterpretation;
  final Future<Uint8List?> Function() _captureFrame;
  Timer? _timer;
  bool _requestInFlight = false;

  void start({Duration interval = const Duration(seconds: 4)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  Future<void> _tick() async {
    if (_requestInFlight) return; // don't pile up requests if one is slow
    final Uint8List? frame = await _captureFrame();
    if (frame == null) return;

    _requestInFlight = true;
    final result = await _repository.interpretFrame(frame);
    _requestInFlight = false;

    result.fold(
      onSuccess: (interpretation) {
        if (interpretation.text.isEmpty) {
          return; // "no clear sign" — nothing to show
        }
        _onInterpretation(
          CaptionLine(
            participantId: _localParticipantId,
            text:
                '${interpretation.text} (?)', // "(?)" marks it as a guess, always
            isFinal: true,
            source: CaptionSource.signLanguageGuess,
          ),
        );
      },
      onFailure: (_) {
        // A single failed interpretation attempt isn't worth
        // surfacing to the user mid-call — it'll simply try again on
        // the next tick.
      },
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// One caption line attributed to a participant.
class CaptionLine {
  const CaptionLine({
    required this.participantId,
    required this.text,
    required this.isFinal,
    this.source = CaptionSource.speech,
  });

  final String participantId;
  final String text;
  final bool isFinal;

  /// Where this line came from — speech-to-text (Phase 4) or a
  /// best-effort sign-language frame interpretation (Phase 6). Shown
  /// distinctly in the overlay so a low-confidence sign guess is never
  /// visually confused with a transcribed spoken word.
  final CaptionSource source;
}

enum CaptionSource { speech, signLanguageGuess }

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
  }) : _room = room,
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
