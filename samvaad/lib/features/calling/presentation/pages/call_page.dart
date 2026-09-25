import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/call.dart';
import '../controllers/call_session_controller.dart';

/// In-call screen: video grid of all participants plus mute/camera/
/// hangup controls. Joins the LiveKit room on entry.
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

  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
    final String? userId = ref.watch(authStateChangesProvider).value?.id;
    final CallSessionState state = ref.watch(callSessionControllerProvider);

    if (userId != null && !_joinTriggered && state is CallSessionIdle) {
      _joinTriggered = true;
      Future.microtask(() {
        ref.read(callSessionControllerProvider.notifier).join(
          callId: widget.call.id,
          call: widget.call,
          userId: userId,
        );
      });
    }

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
          CallSessionConnected(:final room) => Stack(
            children: [
              _ParticipantGrid(room: room),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: _CallControls(
                  micOn: _micOn,
                  cameraOn: _cameraOn,
                  onToggleMic: () {
                    setState(() => _micOn = !_micOn);
                    ref.read(callSessionControllerProvider.notifier).toggleMicrophone(_micOn);
                  },
                  onToggleCamera: () {
                    setState(() => _cameraOn = !_cameraOn);
                    ref.read(callSessionControllerProvider.notifier).toggleCamera(_cameraOn);
                  },
                  onHangUp: () async {
                    await ref
                        .read(callSessionControllerProvider.notifier)
                        .leave(widget.call.id);
                    if (context.mounted) context.pop();
                  },
                ),
              ),
            ],
          ),
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns),
      itemCount: participants.length,
      itemBuilder: (context, index) => _ParticipantTile(participant: participants[index]),
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

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.micOn,
    required this.cameraOn,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onHangUp,
  });

  final bool micOn;
  final bool cameraOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
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