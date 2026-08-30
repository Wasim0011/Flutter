import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider

import '../../../core/constants/colors.dart';
import '../domain/note_model.dart';
import 'providers/piano_provider.dart';
import 'widgets/neon_glow.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────

// Fixed key width — good tap target, never changes regardless of screen size.
// Keyboard is always scrollable; starts centred on Middle C.
const double _whiteKeyWidth  = 52.0;  // proven comfortable tap target
const double _whiteKeyMargin = 1.2;   // gap on each side of a white key
const double _topBarH        = 50.0;
const double _bottomBarH     = 52.0;
const double _minimapH       = 28.0;

// ─────────────────────────────────────────────────────────────────────────────
//  Scroll controller — shared so BottomBar can trigger scroll-to-home
// ─────────────────────────────────────────────────────────────────────────────

// Holds the ONE scroll controller for the keyboard.
// _PianoBodyState registers it; _BottomBar reads it.
final _keyboardScrollProvider =
StateProvider<ScrollController?>((ref) => null);

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
          // Left/right edge-to-edge — keyboard and minimap fill full width.
          // Top/bottom safe insets still respected for notches and nav bars.
          left: false,
          right: false,
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

  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Register scroll controller for HOME button
      ref.read(_keyboardScrollProvider.notifier).state = _scroll;

      // Auto-scroll to Middle C on first open
      if (!_initialScrollDone && _scroll.hasClients) {
        _initialScrollDone = true;
        final notes      = ref.read(allNotesProvider);
        final whiteNotes = notes.where((n) => !n.isSharp).toList();
        final c4Index    = whiteNotes.indexWhere(
                (n) => n.name == 'C' && n.octave == 4);
        if (c4Index >= 0) {
          const slotW   = _whiteKeyWidth + _whiteKeyMargin * 2;
          final vpWidth = _scroll.position.viewportDimension;
          final target  = (c4Index * slotW - vpWidth * 0.25)
              .clamp(0.0, _scroll.position.maxScrollExtent);
          _scroll.jumpTo(target);   // instant on open, no animation
        }
      }
    });
  }

  @override
  void dispose() {
    // Unregister before disposing
    ref.read(_keyboardScrollProvider.notifier).state = null;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes      = ref.watch(allNotesProvider);
    final whiteNotes = notes.where((n) => !n.isSharp).toList();
    final blackNotes = notes.where((n) => n.isSharp).toList();

    return LayoutBuilder(builder: (context, box) {
      final totalWhite = whiteNotes.length;

      // ── Fixed key width — keyboard always scrolls ──────────────────────────
      // Keys stay at a comfortable 52px. Total content is wider than any phone
      // screen, so we always scroll. No squishing, no gaps.
      const double keyW    = _whiteKeyWidth;
      const double margin  = _whiteKeyMargin;
      final double slotW   = keyW + margin * 2;
      final double totalWidth = totalWhite * slotW;

      final double keyH = box.maxHeight * 0.92;
      final double bkW  = keyW * 0.62;
      final double bkH  = keyH * 0.615;

      // Map white-key midi → horizontal index
      final whiteIdx = <int, int>{};
      for (int i = 0; i < whiteNotes.length; i++) {
        whiteIdx[whiteNotes[i].midiNumber] = i;
      }

      final keyboard = _MultiTouchKeyboard(
        notes: notes,
        whiteNotes: whiteNotes,
        blackNotes: blackNotes,
        whiteIdx: whiteIdx,
        keyW: keyW,
        keyH: keyH,
        bkW: bkW,
        bkH: bkH,
        totalWidth: totalWidth,
        scrollController: _scroll,
      );

      // Push dimensions to minimap on every build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(_viewportWidthProvider.notifier).state = box.maxWidth;
        ref.read(_contentWidthProvider.notifier).state  = totalWidth;
        ref.read(_scrollMaxProvider.notifier).state =
            math.max(0, totalWidth - box.maxWidth);
        ref.read(_scrollOffsetProvider.notifier).state =
        _scroll.hasClients ? _scroll.offset : 0;
      });

      // Notify minimap on scroll events
      return NotificationListener<ScrollNotification>(
        onNotification: (n) {
          ref.read(_scrollOffsetProvider.notifier).state =
          _scroll.hasClients ? _scroll.offset : 0;
          ref.read(_scrollMaxProvider.notifier).state =
              math.max(0, totalWidth - box.maxWidth);
          ref.read(_viewportWidthProvider.notifier).state = box.maxWidth;
          ref.read(_contentWidthProvider.notifier).state  = totalWidth;
          return false;
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [AppColors.surface, AppColors.background],
              stops: [0.0, 0.6],
            ),
          ),
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(width: totalWidth, child: keyboard),
          ),
        ),
      );
    });
  }

}

// ─────────────────────────────────────────────────────────────────────────────
//  Multi-touch keyboard
//
//  HOW IT WORKS:
//  Instead of each key having its own Listener (which only catches the initial
//  pointer-down on that key), we put ONE Listener over the whole keyboard Stack.
//  We track every active pointer ID → which NoteModel it is pressing.
//  When a pointer moves between keys, we detect that and fire note-off on the
//  old key + note-on on the new key. This gives slide-to-play behaviour AND
//  true multi-finger polyphony (up to 10 simultaneous fingers).
// ─────────────────────────────────────────────────────────────────────────────

class _MultiTouchKeyboard extends ConsumerStatefulWidget {
  const _MultiTouchKeyboard({
    required this.notes,
    required this.whiteNotes,
    required this.blackNotes,
    required this.whiteIdx,
    required this.keyW,
    required this.keyH,
    required this.bkW,
    required this.bkH,
    required this.totalWidth,
    this.scrollController,
  });

  final List<NoteModel> notes;
  final List<NoteModel> whiteNotes;
  final List<NoteModel> blackNotes;
  final Map<int, int> whiteIdx;
  final double keyW;
  final double keyH;
  final double bkW;
  final double bkH;
  final double totalWidth;
  /// Non-null when the keyboard is inside a ScrollView.
  /// Used to detect scroll-vs-play intent.
  final ScrollController? scrollController;

  @override
  ConsumerState<_MultiTouchKeyboard> createState() =>
      _MultiTouchKeyboardState();
}

class _MultiTouchKeyboardState extends ConsumerState<_MultiTouchKeyboard> {
  // Maps pointer ID → the note it is currently pressing
  final Map<int, NoteModel> _activePointers = {};

  // Tracks the initial DOWN position per pointer to decide scroll vs play.
  final Map<int, Offset> _downPositions = {};

  // Pointers that have been classified as "scrolling" — ignore for notes.
  final Set<int> _scrollingPointers = {};

  // How many pixels of horizontal movement before we call it a scroll.
  static const double _scrollThreshold = 6.0;
  // Play intent requires less vertical movement than horizontal.
  static const double _playThreshold   = 10.0;

  // ── Hit-testing ────────────────────────────────────────────────────────────

  NoteModel? _noteAt(Offset local) {
    final stride = widget.keyW + _whiteKeyMargin * 2;

    // Black keys first — they sit visually on top
    if (local.dy >= 18 && local.dy <= 18 + widget.bkH) {
      for (final note in widget.blackNotes) {
        final prevIdx = widget.whiteIdx[note.midiNumber - 1];
        if (prevIdx == null) continue;
        final left = prevIdx * stride + stride - widget.bkW / 2;
        if (local.dx >= left && local.dx <= left + widget.bkW) {
          return note;
        }
      }
    }

    // White keys
    if (local.dy >= 18) {
      final idx = (local.dx / stride).floor();
      if (idx >= 0 && idx < widget.whiteNotes.length) {
        return widget.whiteNotes[idx];
      }
    }
    return null;
  }

  // ── Pointer handlers ───────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) {
    _downPositions[e.pointer] = e.localPosition;
    // Don't play immediately — wait for move/up to classify intent.
    // This prevents accidental notes when the finger is just resting.
    // We do play on the UP if no significant movement happened.
  }

  void _onPointerMove(PointerMoveEvent e) {
    // Already classified as scroll — let ScrollView handle it
    if (_scrollingPointers.contains(e.pointer)) return;

    final down = _downPositions[e.pointer];
    if (down == null) return;

    final dx = (e.localPosition.dx - down.dx).abs();
    final dy = (e.localPosition.dy - down.dy).abs();

    // If this pointer hasn't been committed to a note yet and moves
    // significantly horizontally → it's a scroll, not a key press.
    if (!_activePointers.containsKey(e.pointer)) {
      if (widget.scrollController != null && dx > _scrollThreshold && dx > dy) {
        // Classify as scroll
        _scrollingPointers.add(e.pointer);
        return;
      }
      // Moved enough vertically OR stayed still — commit as a note press
      if (dy > _playThreshold || dx > _playThreshold) {
        final note = _noteAt(e.localPosition);
        if (note != null) {
          _activePointers[e.pointer] = note;
          ref.read(pianoControllerProvider).onNoteDown(note);
        }
      }
      return;
    }

    // Already committed to a note — handle slide-to-play
    final newNote = _noteAt(e.localPosition);
    final oldNote = _activePointers[e.pointer];
    if (newNote == oldNote) return;

    if (oldNote != null) {
      ref.read(pianoControllerProvider).onNoteUp(oldNote);
    }
    if (newNote != null) {
      _activePointers[e.pointer] = newNote;
      ref.read(pianoControllerProvider).onNoteDown(newNote);
    } else {
      _activePointers.remove(e.pointer);
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    final wasScrolling = _scrollingPointers.remove(e.pointer); // capture result
    final down = _downPositions.remove(e.pointer);
    final note = _activePointers.remove(e.pointer);

    if (note != null) {
      ref.read(pianoControllerProvider).onNoteUp(note);
    } else if (!wasScrolling && down != null) {
      // Only treat as tap if this pointer was NEVER classified as a scroll
      final dx = (e.localPosition.dx - down.dx).abs();
      final dy = (e.localPosition.dy - down.dy).abs();
      if (dx < _scrollThreshold && dy < _scrollThreshold) {
        final tapped = _noteAt(e.localPosition);
        if (tapped != null) {
          ref.read(pianoControllerProvider).onNoteDown(tapped);
          Future.delayed(const Duration(milliseconds: 80), () {
            ref.read(pianoControllerProvider).onNoteUp(tapped);
          });
        }
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _downPositions.remove(e.pointer);
    _scrollingPointers.remove(e.pointer);
    final note = _activePointers.remove(e.pointer);
    if (note != null) {
      ref.read(pianoControllerProvider).onNoteUp(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stride = widget.keyW + _whiteKeyMargin * 2;

    return Listener(
      // HitTestBehavior.opaque so the Listener catches ALL touches on the
      // keyboard area, not just ones that land directly on a painted pixel.
      behavior: HitTestBehavior.opaque,
      onPointerDown:   _onPointerDown,
      onPointerMove:   _onPointerMove,
      onPointerUp:     _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        children: [
          // Wood rail
          const Positioned(
            top: 0, left: 0, right: 0, height: 20,
            child: _WoodRail(),
          ),

          // White keys (no individual Listeners — hit testing done above)
          Positioned(
            top: 18, left: 0, right: 0,
            child: Row(
              children: widget.whiteNotes.map((n) => _WhiteKeyVisual(
                note: n,
                width: stride,
                height: widget.keyH,
              )).toList(),
            ),
          ),

          // Black keys
          for (final note in widget.blackNotes)
                () {
              final prevIdx = widget.whiteIdx[note.midiNumber - 1];
              if (prevIdx == null) return const SizedBox.shrink();
              final left = prevIdx * stride + stride - widget.bkW / 2;
              return Positioned(
                top: 18,
                left: left,
                child: _BlackKeyVisual(
                  note: note,
                  width: widget.bkW,
                  height: widget.bkH,
                ),
              );
            }(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Visual-only key widgets (no Listener — touch handled by _MultiTouchKeyboard)
// ─────────────────────────────────────────────────────────────────────────────

class _WhiteKeyVisual extends ConsumerStatefulWidget {
  const _WhiteKeyVisual({
    required this.note,
    required this.width,
    required this.height,
  });
  final NoteModel note;
  final double width;
  final double height;

  @override
  ConsumerState<_WhiteKeyVisual> createState() => _WhiteKeyVisualState();
}

class _WhiteKeyVisualState extends ConsumerState<_WhiteKeyVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _press;
  final int _prevTrigger = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _press = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = ref.watch(
      pressedNotesProvider.select((s) => s.contains(widget.note.midiNumber)),
    );

    // Drive press animation from provider state
    if (isPressed) {
      _anim.forward();
    } else {
      _anim.reverse();
    }

    return AnimatedBuilder(
      animation: _press,
      builder: (_, __) {
        final t = _press.value;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              // Shadow layer
              Positioned(
                left: 0, right: 0, top: 2 + t * 3, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    color: AppColors.whiteKeyShadow,
                  ),
                ),
              ),
              // Key face
              Positioned(
                left: 0, right: 0, top: 0, bottom: t * 4,
                child: PulsingGlow(
                  isActive: isPressed,
                  color: AppColors.glowAmber,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: _whiteKeyMargin),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      gradient: isPressed
                          ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.whiteKeyPressed,
                          AppColors.whiteKeyPressedB,
                          AppColors.whiteKeyShadow,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      )
                          : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.whiteKeyTop,
                          AppColors.whiteKey,
                          AppColors.whiteKeyBottom,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      boxShadow: isPressed
                          ? [BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                      )]
                          : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          offset: const Offset(0, 3),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          offset: const Offset(1, 0),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Gloss strip
                        Positioned(
                          top: 0, left: 2, right: 2, height: 18,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(3),
                                bottomRight: Radius.circular(3),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(isPressed ? 0.0 : 0.55),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Amber pressed wash
                        if (isPressed)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.glowAmber.withOpacity(0.22),
                                      AppColors.glowAmber.withOpacity(0.04),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Note label
                        Positioned(
                          bottom: 10, left: 0, right: 0,
                          child: Text(
                            widget.note.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isPressed
                                  ? AppColors.glowAmberB
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlackKeyVisual extends ConsumerStatefulWidget {
  const _BlackKeyVisual({
    required this.note,
    required this.width,
    required this.height,
  });
  final NoteModel note;
  final double width;
  final double height;

  @override
  ConsumerState<_BlackKeyVisual> createState() => _BlackKeyVisualState();
}

class _BlackKeyVisualState extends ConsumerState<_BlackKeyVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _press;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 45),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _press = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = ref.watch(
      pressedNotesProvider.select((s) => s.contains(widget.note.midiNumber)),
    );

    if (isPressed) {
      _anim.forward();
    } else {
      _anim.reverse();
    }

    return AnimatedBuilder(
      animation: _press,
      builder: (_, __) {
        final t = _press.value;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              // Shadow base
              Positioned(
                left: 1, right: 1, top: 2 + t * 2, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                    color: Colors.black,
                  ),
                ),
              ),
              // Key face
              Positioned(
                left: 0, right: 0, top: 0, bottom: t * 3,
                child: NeonGlow(
                  isActive: isPressed,
                  color: AppColors.glowCyan,
                  borderRadius: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(5),
                        bottomRight: Radius.circular(5),
                      ),
                      gradient: isPressed
                          ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.blackKeyPressed,
                          AppColors.blackKeyPressedB,
                          AppColors.blackKeyBase,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                          : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.blackKeySheen,
                          AppColors.blackKeyTop,
                          AppColors.blackKeyMid,
                          AppColors.blackKeyBase,
                        ],
                        stops: const [0.0, 0.08, 0.5, 1.0],
                      ),
                      boxShadow: isPressed
                          ? [BoxShadow(
                        color: Colors.black.withOpacity(0.9),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      )]
                          : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.85),
                          offset: const Offset(0, 5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                        const BoxShadow(
                          color: Color(0x28FFFFFF),
                          offset: Offset(-1, 0),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Gloss strip
                        Positioned(
                          top: 0, left: 3, right: 3, height: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(3),
                                bottomRight: Radius.circular(3),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(isPressed ? 0.0 : 0.18),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isPressed)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.glowCyan.withOpacity(0.28),
                                      AppColors.glowCyan.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        // No horizontal padding — minimap keys must span edge-to-edge,
        // identical to the wood rail and keyboard above/below it.
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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

          // ── Home button — scrolls keyboard to Middle C (C4) ──────────────
          _HomeButton(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Home button — snaps keyboard scroll back to Middle C (C4)
//
//  WHY THIS EXISTS:
//  A real piano has 88 keys. Your screen shows ~2 octaves at a time.
//  After exploring bass or treble, one tap brings you back to Middle C —
//  the "home base" of every pianist. Top apps (Simply Piano, Perfect Piano)
//  all have this.
// ─────────────────────────────────────────────────────────────────────────────

class _HomeButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends ConsumerState<_HomeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _scrollToMiddleC() {
    final controller = ref.read(_keyboardScrollProvider);
    if (controller == null || !controller.hasClients) return;

    final notes      = ref.read(allNotesProvider);
    final whiteNotes = notes.where((n) => !n.isSharp).toList();

    // Find C4 (Middle C) index among white keys.
    // We want C4 to appear at the LEFT edge of the visible viewport
    // (not centred), because that's how real pianos look — you can see
    // the bass to the left in the minimap, and the treble extends right.
    // If C4 is not in range, go to the note closest to MIDI 60.
    int targetIndex = whiteNotes.indexWhere(
            (n) => n.name == 'C' && n.octave == 4);

    if (targetIndex < 0) {
      // C4 not in range — find the white key closest to MIDI 60 (C4)
      int closest = 0;
      int minDist = 999;
      for (int i = 0; i < whiteNotes.length; i++) {
        final dist = (whiteNotes[i].midiNumber - 60).abs();
        if (dist < minDist) { minDist = dist; closest = i; }
      }
      targetIndex = closest;
    }

    final vpWidth = controller.position.viewportDimension;
    const stride  = _whiteKeyWidth + _whiteKeyMargin * 2;

    // Position C4 at 25% from the left of the viewport —
    // this feels most natural: you see 1/4 bass keys to the left,
    // and 3/4 treble keys to the right, matching a real seated pianist's view.
    final targetPx = targetIndex * stride;
    final scrollTo = (targetPx - vpWidth * 0.25)
        .clamp(0.0, controller.position.maxScrollExtent);

    controller.animateTo(
      scrollTo,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );

    // Press animation + haptic
    _pulse.reverse().then((_) => _pulse.forward());
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _scrollToMiddleC,
      child: ScaleTransition(
        scale: _pulse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.panelBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowAmber.withOpacity(0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.home_rounded, color: AppColors.glowAmber, size: 14),
              SizedBox(width: 6),
              Text(
                'MIDDLE C',
                style: TextStyle(
                  color: AppColors.glowAmber,
                  fontSize: 9,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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