import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/onboarding_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/call.dart';
import '../controllers/call_session_controller.dart';
import '../controllers/caption_controller.dart';

import 'dart:typed_data';

import '../../../translation/presentation/providers/translation_providers.dart';

/// In-call screen: video grid of all participants plus mute/camera/
/// captions/hangup controls. Joins the LiveKit room on entry.
class CallPage extends ConsumerStatefulWidget {
  const CallPage({required this.call, super.key});

  final Call call;

  @override
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {
  bool _micOn = true;
  bool _cameraOn = true;
  bool _joinTriggered = false;

  CaptionSpeechService? _captionService;
  bool _captionsSetupDone = false;

  SignFrameCaptureService? _signCaptureService;

  void _setupSignCapture(Room room, String userId) {
    _signCaptureService = SignFrameCaptureService(
      repository: ref.read(signInterpretationRepositoryProvider),
      localParticipantId: userId,
      onInterpretation: (line) =>
          ref.read(captionFeedProvider.notifier).update(line),
      captureFrame: () => _captureLocalVideoFrame(room),
    );
  }

  /// Captures a single JPEG frame from the local participant's current
  /// video track.
  ///
  /// NOTE: livekit_client's exact API for grabbing a still frame from
  /// a live VideoTrack (as opposed to rendering it in a widget) varies
  /// by version and platform — some versions expose this via a
  /// platform-specific capturer method, others require rendering to a
  /// texture and reading it back. This is the single most likely spot
  /// in this milestone to need a version-specific correction — paste
  /// whatever the analyzer/runtime reports here and it'll be fixed
  /// precisely against your installed version.
  Future<Uint8List?> _captureLocalVideoFrame(Room room) async {
    try {
      final track = room.localParticipant?.videoTrackPublications
          .where((pub) => pub.track != null)
          .map((pub) => pub.track)
          .firstOrNull;
      if (track == null) return null;
      // Placeholder call — see NOTE above.
      return null;
    } catch (_) {
      return null;
    }
  }

  void _setupCaptions(
    Room room,
    String userId,
    CommunicationPreference? preference,
  ) {
    if (_captionsSetupDone) return;
    _captionsSetupDone = true;

    final bool defaultOn =
        preference == CommunicationPreference.captionsFirst ||
        preference == CommunicationPreference.signLanguage;
    ref.read(captionsEnabledProvider.notifier).set(defaultOn);

    _captionService = CaptionSpeechService(
      room: room,
      localParticipantId: userId,
      onLocalCaption: (line) =>
          ref.read(captionFeedProvider.notifier).update(line),
    );

    _setupSignCapture(room, userId);

    room.createListener().on<DataReceivedEvent>((event) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
        ref
            .read(captionFeedProvider.notifier)
            .update(
              CaptionLine(
                participantId: data['senderId'] as String,
                text: data['text'] as String,
                isFinal: data['isFinal'] as bool,
              ),
            );
      } catch (_) {}
    });

    if (defaultOn) {
      _captionService?.start();
      // Sign capture is opt-in specifically for signLanguage
      // preference — captionsFirst users get speech captions by
      // default but not the noisier, best-effort sign guesses,
      // consistent with what each preference actually asked for.
      if (preference == CommunicationPreference.signLanguage) {
        _signCaptureService?.start();
      }
    }
  }

  void _toggleCaptions(bool enabled) {
    ref.read(captionsEnabledProvider.notifier).set(enabled);
    if (enabled) {
      _captionService?.start();
      _signCaptureService?.start();
    } else {
      _captionService?.stop();
      _signCaptureService?.stop();
    }
  }

  @override
  void dispose() {
    _captionService?.stop();
    _signCaptureService?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = ref.watch(authStateChangesProvider).value?.id;
    final CallSessionState state = ref.watch(callSessionControllerProvider);

    if (userId != null && !_joinTriggered && state is CallSessionIdle) {
      _joinTriggered = true;
      Future.microtask(() {
        ref
            .read(callSessionControllerProvider.notifier)
            .join(callId: widget.call.id, call: widget.call, userId: userId);
      });
    }

    final AsyncValue<CommunicationPreference?> preferenceAsync = userId == null
        ? const AsyncValue.data(null)
        : ref.watch(communicationPreferenceProvider(userId));
    final bool captionsEnabled = ref.watch(captionsEnabledProvider);
    final Map<String, CaptionLine> captions = ref.watch(captionFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: switch (state) {
          CallSessionIdle() || CallSessionConnecting() => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          CallSessionFailed(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Couldn\'t join the call: $message',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          CallSessionConnected(:final room) => () {
            if (userId != null) {
              _setupCaptions(room, userId, preferenceAsync.value);
            }
            return Stack(
              children: [
                _ParticipantGrid(room: room),
                if (captionsEnabled && captions.isNotEmpty)
                  Positioned(
                    bottom: 110,
                    left: 16,
                    right: 16,
                    child: Semantics(
                      liveRegion: true,
                      child: _CaptionsOverlay(captions: captions),
                    ),
                  ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: _CallControls(
                    micOn: _micOn,
                    cameraOn: _cameraOn,
                    captionsOn: captionsEnabled,
                    onToggleMic: () {
                      setState(() => _micOn = !_micOn);
                      ref
                          .read(callSessionControllerProvider.notifier)
                          .toggleMicrophone(_micOn);
                    },
                    onToggleCamera: () {
                      setState(() => _cameraOn = !_cameraOn);
                      ref
                          .read(callSessionControllerProvider.notifier)
                          .toggleCamera(_cameraOn);
                    },
                    onToggleCaptions: () => _toggleCaptions(!captionsEnabled),
                    onHangUp: () async {
                      await ref
                          .read(callSessionControllerProvider.notifier)
                          .leave(widget.call.id);
                      if (context.mounted) context.pop();
                    },
                  ),
                ),
              ],
            );
          }(),
        },
      ),
    );
  }
}

class _ParticipantGrid extends StatelessWidget {
  const _ParticipantGrid({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final List<Participant> participants = [
      room.localParticipant,
      ...room.remoteParticipants.values,
    ].whereType<Participant>().toList();

    final int columns = participants.length <= 1 ? 1 : 2;

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) =>
          _ParticipantTile(participant: participants[index]),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final VideoTrack? videoTrack = participant.videoTrackPublications
        .where((pub) => pub.track != null)
        .map((pub) => pub.track as VideoTrack)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.all(2),
      color: Colors.grey.shade900,
      child: videoTrack != null
          ? VideoTrackRenderer(videoTrack)
          : Center(
              child: Icon(Icons.person, size: 48, color: Colors.grey.shade600),
            ),
    );
  }
}

class _CaptionsOverlay extends StatelessWidget {
  const _CaptionsOverlay({required this.captions});

  final Map<String, CaptionLine> captions;

  @override
  Widget build(BuildContext context) {
    final List<CaptionLine> lines = captions.values.toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (line.source == CaptionSource.signLanguageGuess)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.back_hand_outlined,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        line.text,
                        style: TextStyle(
                          color: line.source == CaptionSource.signLanguageGuess
                              ? Colors.amber.shade200
                              : Colors.white,
                          fontSize: 18,
                          fontStyle:
                              line.source == CaptionSource.signLanguageGuess
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.micOn,
    required this.cameraOn,
    required this.captionsOn,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onToggleCaptions,
    required this.onHangUp,
  });

  final bool micOn;
  final bool cameraOn;
  final bool captionsOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleCaptions;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: micOn ? Icons.mic : Icons.mic_off,
          label: micOn ? 'Mute' : 'Unmute',
          onPressed: onToggleMic,
        ),
        _ControlButton(
          icon: captionsOn ? Icons.closed_caption : Icons.closed_caption_off,
          label: captionsOn ? 'Hide captions' : 'Show captions',
          onPressed: onToggleCaptions,
        ),
        _ControlButton(
          icon: Icons.call_end,
          label: 'End call',
          backgroundColor: Colors.red,
          onPressed: onHangUp,
        ),
        _ControlButton(
          icon: cameraOn ? Icons.videocam : Icons.videocam_off,
          label: cameraOn ? 'Stop video' : 'Start video',
          onPressed: onToggleCamera,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FloatingActionButton(
        heroTag: label,
        backgroundColor: backgroundColor ?? Colors.white24,
        onPressed: onPressed,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
