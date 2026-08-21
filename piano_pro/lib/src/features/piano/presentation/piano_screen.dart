import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider

import '../../../core/constants/colors.dart';
import '../data/audio_service.dart';
import '../domain/note_model.dart';
import 'providers/piano_provider.dart';
import 'widgets/piano_key.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────

const double _whiteKeyWidth  = 52.0;
const double _whiteKeyMargin = 1.5;  // gap between white keys
const double _topBarH        = 50.0;
const double _bottomBarH     = 52.0;
const double _minimapH       = 28.0;

// ─────────────────────────────────────────────────────────────────────────────
//  Root screen
// ─────────────────────────────────────────────────────────────────────────────

class PianoScreen extends ConsumerStatefulWidget {
  const PianoScreen({super.key});

  @override
  ConsumerState<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends ConsumerState<PianoScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(pianoControllerProvider).initialize();
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // When octave shifts reload samples
    ref.listen(octaveShiftProvider, (prev, next) {
      if (prev != next) {
        ref.read(pianoControllerProvider).onOctaveChanged();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(),
              Expanded(
                child: _initialized
                    ? _PianoBody()
                    : _LoadingScreen(),
              ),
              _MinimapBar(),
              _BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Loading
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.glowAmber),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'LOADING SAMPLES',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'preparing your piano',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sustain = ref.watch(sustainProvider);
    final shift   = ref.watch(octaveShiftProvider);

    return Container(
      height: _topBarH,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.panelBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.piano_rounded,
                  color: AppColors.glowAmber, size: 22),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.glowAmberC, AppColors.glowAmber],
                ).createShader(b),
                child: const Text(
                  'PIANO PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── Octave shift ──────────────────────────────────────────────────
          _OctaveControl(shift: shift, ref: ref),

          const SizedBox(width: 16),
          _Divider(),
          const SizedBox(width: 16),

          // ── Sustain toggle ────────────────────────────────────────────────
          _SustainButton(
            active: sustain,
            onTap: () => ref.read(pianoControllerProvider).toggleSustain(),
          ),

          const SizedBox(width: 16),
          _Divider(),
          const SizedBox(width: 16),

          // ── Active notes display ──────────────────────────────────────────
          _ActiveNoteDisplay(),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 28, color: AppColors.panelBorder);
}

// ── Octave control ─────────────────────────────────────────────────────────

class _OctaveControl extends StatelessWidget {
  const _OctaveControl({required this.shift, required this.ref});
  final int shift;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Label('OCT'),
        const SizedBox(width: 10),
        _StepBtn(
          icon: Icons.keyboard_arrow_left_rounded,
          enabled: shift > -2,
          onTap: () => ref.read(octaveShiftProvider.notifier).state--,
        ),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            '${shift >= 0 ? '+' : ''}$shift',
            key: ValueKey(shift),
            style: const TextStyle(
              color: AppColors.glowAmber,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _StepBtn(
          icon: Icons.keyboard_arrow_right_rounded,
          enabled: shift < 2,
          onTap: () => ref.read(octaveShiftProvider.notifier).state++,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceHigh
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: enabled
                ? AppColors.panelBorder
                : AppColors.textMuted.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Sustain button ────────────────────────────────────────────────────────

class _SustainButton extends StatelessWidget {
  const _SustainButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.glowAmber.withOpacity(0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? AppColors.glowAmber : AppColors.panelBorder,
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
            BoxShadow(
              color: AppColors.glowAmber.withOpacity(0.25),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              active
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              size: 13,
              color:
              active ? AppColors.glowAmber : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'SUSTAIN',
              style: TextStyle(
                color: active
                    ? AppColors.glowAmber
                    : AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    ),
  );
}

// ── Active note display ────────────────────────────────────────────────────

class _ActiveNoteDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pressed = ref.watch(pressedNotesProvider);
    final notes   = ref.watch(allNotesProvider);

    final names = notes
        .where((n) => pressed.contains(n.midiNumber))
        .map((n) => n.fullName)
        .join('  ');

    return SizedBox(
      width: 110,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: Text(
          names.isEmpty ? '· · ·' : names,
          key: ValueKey(names),
          style: TextStyle(
            color: names.isEmpty
                ? AppColors.textMuted
                : AppColors.glowAmber,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Piano body + keyboard
// ─────────────────────────────────────────────────────────────────────────────

class _PianoBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PianoBody> createState() => _PianoBodyState();
}

class _PianoBodyState extends ConsumerState<_PianoBody> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes      = ref.watch(allNotesProvider);
    final whiteNotes = notes.where((n) => !n.isSharp).toList();
    final blackNotes = notes.where((n) => n.isSharp).toList();

    final totalWhite = whiteNotes.length;
    final totalWidth = totalWhite * (_whiteKeyWidth + _whiteKeyMargin * 2);

    return LayoutBuilder(builder: (context, box) {
      final keyH   = box.maxHeight * 0.92;
      final bkW    = _whiteKeyWidth * 0.64;
      final bkH    = keyH * 0.615;

      // Map white-key midi → horizontal index
      final whiteIdx = <int, int>{};
      for (int i = 0; i < whiteNotes.length; i++) {
        whiteIdx[whiteNotes[i].midiNumber] = i;
      }

      // Notify minimap of scroll position
      return NotificationListener<ScrollNotification>(
        onNotification: (n) {
          ref.read(_scrollOffsetProvider.notifier).state =
          _scroll.hasClients ? _scroll.offset : 0;
          ref.read(_scrollMaxProvider.notifier).state =
          _scroll.hasClients
              ? math.max(0, totalWidth - box.maxWidth)
              : 1;
          ref.read(_viewportWidthProvider.notifier).state = box.maxWidth;
          ref.read(_contentWidthProvider.notifier).state  = totalWidth;
          return false;
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [AppColors.surface, AppColors.background],
              stops: const [0.0, 0.6],
            ),
          ),
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              child: Stack(
                children: [
                  // Wood rail
                  Positioned(
                    top: 0, left: 0, right: 0, height: 20,
                    child: const _WoodRail(),
                  ),

                  // White keys
                  Positioned(
                    top: 18, left: 0, right: 0,
                    child: Row(
                      children: whiteNotes
                          .map((n) => WhitePianoKey(
                        note: n,
                        width: _whiteKeyWidth,
                        height: keyH,
                      ))
                          .toList(),
                    ),
                  ),

                  // Black keys
                  for (final note in blackNotes)
                    _positionedBlackKey(
                        note, whiteIdx, bkW, bkH),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _positionedBlackKey(
      NoteModel note,
      Map<int, int> whiteIdx,
      double bkW,
      double bkH,
      ) {
    final prevIdx = whiteIdx[note.midiNumber - 1];
    if (prevIdx == null) return const SizedBox.shrink();

    final stride = _whiteKeyWidth + _whiteKeyMargin * 2;
    final left   = prevIdx * stride + stride - bkW / 2 + _whiteKeyMargin;

    return Positioned(
      top: 18,
      left: left,
      child: BlackPianoKey(note: note, width: bkW, height: bkH),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Wood rail
// ─────────────────────────────────────────────────────────────────────────────

class _WoodRail extends StatelessWidget {
  const _WoodRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [
            AppColors.woodLight,
            AppColors.woodMid,
            AppColors.woodDark,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _woodScrew(),
              const Spacer(),
              _woodScrew(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _woodScrew() => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.woodDark,
      border: Border.all(color: AppColors.woodSheen, width: 1),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Minimap bar — shows viewport position across full keyboard
// ─────────────────────────────────────────────────────────────────────────────

// Providers just for minimap scroll sync
final _scrollOffsetProvider  = StateProvider<double>((ref) => 0);
final _scrollMaxProvider     = StateProvider<double>((ref) => 1);
final _viewportWidthProvider = StateProvider<double>((ref) => 1);
final _contentWidthProvider  = StateProvider<double>((ref) => 1);

class _MinimapBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset   = ref.watch(_scrollOffsetProvider);
    final maxOff   = ref.watch(_scrollMaxProvider);
    final vpW      = ref.watch(_viewportWidthProvider);
    final contentW = ref.watch(_contentWidthProvider);

    final ratio    = contentW > 0 ? vpW / contentW : 1.0;
    final position = maxOff > 0 ? offset / maxOff : 0.0;

    final notes      = ref.watch(allNotesProvider);
    final pressed    = ref.watch(pressedNotesProvider);
    final whiteNotes = notes.where((n) => !n.isSharp).toList();
    final blackNotes = notes.where((n) => n.isSharp).toList();
    final totalWhite = whiteNotes.length;

    // White index lookup
    final whiteIdx = <int, int>{};
    for (int i = 0; i < whiteNotes.length; i++) {
      whiteIdx[whiteNotes[i].midiNumber] = i;
    }

    return Container(
      height: _minimapH,
      color: AppColors.panelBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: LayoutBuilder(builder: (_, box) {
          final w        = box.maxWidth;
          final keyW     = w / totalWhite;
          final bkW      = keyW * 0.6;

          return Stack(
            children: [
              // ── White key strips ──────────────────────────────────────────
              Row(
                children: whiteNotes.map((n) {
                  final isPressed = pressed.contains(n.midiNumber);
                  return Container(
                    width: keyW - 0.8,
                    margin: const EdgeInsets.only(right: 0.8),
                    decoration: BoxDecoration(
                      color: isPressed
                          ? AppColors.glowAmber
                          : const Color(0xFFD0C8B0),
                      borderRadius: const BorderRadius.only(
                        bottomLeft:  Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: isPressed
                          ? [
                        BoxShadow(
                          color: AppColors.glowAmber.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ]
                          : null,
                    ),
                  );
                }).toList(),
              ),

              // ── Black key strips ──────────────────────────────────────────
              for (final note in blackNotes)
                    () {
                  final pIdx = whiteIdx[note.midiNumber - 1];
                  if (pIdx == null) return const SizedBox.shrink();
                  final left = pIdx * keyW + keyW - bkW / 2;
                  final isPressed = pressed.contains(note.midiNumber);
                  return Positioned(
                    top: 0,
                    left: left,
                    width: bkW,
                    bottom: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPressed
                            ? AppColors.glowCyan
                            : AppColors.blackKeyMid,
                        borderRadius: const BorderRadius.only(
                          bottomLeft:  Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                        boxShadow: isPressed
                            ? [
                          BoxShadow(
                            color: AppColors.glowCyan.withOpacity(0.7),
                            blurRadius: 6,
                          ),
                        ]
                            : null,
                      ),
                    ),
                  );
                }(),

              // ── Viewport window ───────────────────────────────────────────
              Positioned.fill(
                child: LayoutBuilder(builder: (_, b2) {
                  final winW = b2.maxWidth * ratio;
                  final winL = (b2.maxWidth - winW) * position;
                  return Stack(
                    children: [
                      // Dimmed outside areas
                      Positioned(left: 0, top: 0, bottom: 0, width: winL,
                          child: Container(
                              color: AppColors.background.withOpacity(0.55))),
                      Positioned(
                          left: winL + winW, top: 0, bottom: 0,
                          right: 0,
                          child: Container(
                              color: AppColors.background.withOpacity(0.55))),
                      // Viewport indicator border
                      Positioned(
                        left: winL, top: 0, bottom: 0, width: winW,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.glowAmber.withOpacity(0.7),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom bar — volume
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(volumeProvider);

    return Container(
      height: _bottomBarH,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.panelBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Label ──────────────────────────────────────────────────────
          const _Label('VOLUME'),
          const SizedBox(width: 12),

          // ── Icon ───────────────────────────────────────────────────────
          Icon(
            volume < 0.05
                ? Icons.volume_off_rounded
                : volume < 0.5
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded,
            color: AppColors.glowAmber,
            size: 18,
          ),
          const SizedBox(width: 8),

          // ── Slider ─────────────────────────────────────────────────────
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.glowAmber,
                inactiveTrackColor: AppColors.panelBorder,
                thumbColor: AppColors.glowAmberC,
                overlayColor:
                AppColors.glowAmber.withOpacity(0.18),
                trackShape: const _GlowTrackShape(),
              ),
              child: Slider(
                value: volume,
                min: 0,
                max: 1,
                onChanged: (v) => ref.read(pianoControllerProvider).setVolume(v),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Volume % ───────────────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Text(
              '${(volume * 100).round()}%',
              style: const TextStyle(
                color: AppColors.glowAmber,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // ── Scroll hint ────────────────────────────────────────────────
          Row(
            children: const [
              Icon(Icons.swipe_rounded,
                  color: AppColors.textMuted, size: 14),
              SizedBox(width: 4),
              Text(
                'SWIPE KEYS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom track shape with a subtle glow on the active portion
class _GlowTrackShape extends RoundedRectSliderTrackShape {
  const _GlowTrackShape();

  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required Animation<double> enableAnimation,
        required TextDirection textDirection,
        required Offset thumbCenter,
        Offset? secondaryOffset,
        bool isDiscrete = false,
        bool isEnabled = false,
        double additionalActiveTrackHeight = 2,
      }) {
    super.paint(
      context, offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    // Glow over active track
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = AppColors.glowAmber.withOpacity(0.35);
    final activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top - 1,
      thumbCenter.dx,
      trackRect.bottom + 1,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, const Radius.circular(3)),
      paint,
    );
  }
}