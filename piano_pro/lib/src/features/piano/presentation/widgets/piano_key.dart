import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/note_model.dart';
import '../providers/piano_provider.dart';
import 'neon_glow.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  WHITE KEY
// ═══════════════════════════════════════════════════════════════════════════════

class WhitePianoKey extends ConsumerStatefulWidget {
  const WhitePianoKey({
    super.key,
    required this.note,
    required this.width,
    required this.height,
  });

  final NoteModel note;
  final double width;
  final double height;

  @override
  ConsumerState<WhitePianoKey> createState() => _WhitePianoKeyState();
}

class _WhitePianoKeyState extends ConsumerState<WhitePianoKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _press;   // 0 = up, 1 = fully down
  int _rippleTrigger = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 55),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _press = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _down() {
    HapticFeedback.lightImpact();
    _anim.forward();
    _rippleTrigger++;
    ref.read(pianoControllerProvider).onNoteDown(widget.note);
  }

  void _up() {
    _anim.reverse();
    ref.read(pianoControllerProvider).onNoteUp(widget.note);
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = ref.watch(
      pressedNotesProvider.select((s) => s.contains(widget.note.midiNumber)),
    );

    return Listener(
      onPointerDown: (_) => _down(),
      onPointerUp:   (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, __) {
          final t = _press.value;          // 0..1

          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              children: [
                // ── Shadow layer (simulates physical depth) ──────────────────
                Positioned(
                  left: 0, right: 0,
                  top: 2 + t * 3,          // shadow shrinks as key depresses
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft:  Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      color: AppColors.whiteKeyShadow,
                    ),
                  ),
                ),

                // ── Key face ─────────────────────────────────────────────────
                Positioned(
                  left: 0, right: 0,
                  top: 0,
                  // Pivots at top — bottom appears to push down
                  bottom: t * 4,
                  child: PulsingGlow(
                    isActive: isPressed,
                    color: AppColors.glowAmber,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft:  Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        gradient: isPressed
                            ? LinearGradient(
                          begin: Alignment.topCenter,
                          end:   Alignment.bottomCenter,
                          colors: [
                            AppColors.whiteKeyPressed,
                            AppColors.whiteKeyPressedB,
                            AppColors.whiteKeyShadow,
                          ],
                          stops: const [0.0, 0.65, 1.0],
                        )
                            : LinearGradient(
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                          colors: [
                            AppColors.whiteKeyTop,
                            AppColors.whiteKey,
                            AppColors.whiteKeyBottom,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        boxShadow: isPressed
                            ? [
                          // Inset-style: top dark line when depressed
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(0, -2),
                            blurRadius: 4,
                          ),
                        ]
                            : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            offset: const Offset(0, 3),
                            blurRadius: 5,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            offset: const Offset(1, 0),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Gloss strip at the very top of the key
                          Positioned(
                            top: 0, left: 2, right: 2,
                            height: 18,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft:  Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end:   Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(
                                        alpha: isPressed ? 0.0 : 0.55),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Pressed amber wash
                          if (isPressed)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft:  Radius.circular(6),
                                  bottomRight: Radius.circular(6),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end:   Alignment.bottomCenter,
                                      colors: [
                                        AppColors.glowAmber.withValues(alpha: 0.22),
                                        AppColors.glowAmber.withValues(alpha: 0.04),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Ripple
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft:  Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                              child: KeyRipple(
                                trigger: _rippleTrigger,
                                color: AppColors.glowAmber,
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BLACK KEY
// ═══════════════════════════════════════════════════════════════════════════════

class BlackPianoKey extends ConsumerStatefulWidget {
  const BlackPianoKey({
    super.key,
    required this.note,
    required this.width,
    required this.height,
  });

  final NoteModel note;
  final double width;
  final double height;

  @override
  ConsumerState<BlackPianoKey> createState() => _BlackPianoKeyState();
}

class _BlackPianoKeyState extends ConsumerState<BlackPianoKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _press;
  int _rippleTrigger = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 45),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _press = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _down() {
    HapticFeedback.selectionClick();
    _anim.forward();
    _rippleTrigger++;
    ref.read(pianoControllerProvider).onNoteDown(widget.note);
  }

  void _up() {
    _anim.reverse();
    ref.read(pianoControllerProvider).onNoteUp(widget.note);
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = ref.watch(
      pressedNotesProvider.select((s) => s.contains(widget.note.midiNumber)),
    );

    return Listener(
      onPointerDown: (_) => _down(),
      onPointerUp:   (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, __) {
          final t = _press.value;

          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              children: [
                // ── Shadow base ───────────────────────────────────────────────
                Positioned(
                  left: 1, right: 1,
                  top: 2 + t * 2,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft:  Radius.circular(5),
                        bottomRight: Radius.circular(5),
                      ),
                      color: Colors.black,
                    ),
                  ),
                ),

                // ── Key face ──────────────────────────────────────────────────
                Positioned(
                  left: 0, right: 0,
                  top: 0,
                  bottom: t * 3,
                  child: NeonGlow(
                    isActive: isPressed,
                    color: AppColors.glowCyan,
                    borderRadius: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft:  Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                        gradient: isPressed
                            ? LinearGradient(
                          begin: Alignment.topCenter,
                          end:   Alignment.bottomCenter,
                          colors: [
                            AppColors.blackKeyPressed,
                            AppColors.blackKeyPressedB,
                            AppColors.blackKeyBase,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        )
                            : LinearGradient(
                          begin: Alignment.topCenter,
                          end:   Alignment.bottomCenter,
                          colors: [
                            AppColors.blackKeySheen,
                            AppColors.blackKeyTop,
                            AppColors.blackKeyMid,
                            AppColors.blackKeyBase,
                          ],
                          stops: const [0.0, 0.08, 0.5, 1.0],
                        ),
                        boxShadow: isPressed
                            ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.9),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ]
                            : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.85),
                            offset: const Offset(0, 5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                          // Left edge highlight (3-D bevel)
                          const BoxShadow(
                            color: Color(0x28FFFFFF),
                            offset: Offset(-1, 0),
                            blurRadius: 1,
                          ),
                          // Right edge shadow
                          const BoxShadow(
                            color: Color(0x55000000),
                            offset: Offset(1, 0),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Gloss strip
                          Positioned(
                            top: 0, left: 3, right: 3,
                            height: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft:  Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end:   Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(
                                        alpha: isPressed ? 0.0 : 0.18),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Pressed cyan wash
                          if (isPressed)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft:  Radius.circular(5),
                                  bottomRight: Radius.circular(5),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end:   Alignment.bottomCenter,
                                      colors: [
                                        AppColors.glowCyan.withValues(alpha: 0.28),
                                        AppColors.glowCyan.withValues(alpha: 0.05),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Ripple
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft:  Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                              child: KeyRipple(
                                trigger: _rippleTrigger,
                                color: AppColors.glowCyan,
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
      ),
    );
  }
}
