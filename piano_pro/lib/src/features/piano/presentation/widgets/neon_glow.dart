import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

// ── Static neon outline glow ──────────────────────────────────────────────────

class NeonGlow extends StatelessWidget {
  const NeonGlow({
    super.key,
    required this.child,
    required this.isActive,
    this.color = AppColors.glowAmber,
    this.intensity = 1.0,
    this.borderRadius = 4.0,
  });

  final Widget child;
  final bool isActive;
  final Color color;
  final double intensity;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return child;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius + 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08 * intensity),
            blurRadius: 40,
            spreadRadius: 12,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.20 * intensity),
            blurRadius: 18,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.50 * intensity),
            blurRadius: 7,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Animated pulse glow for held keys ─────────────────────────────────────────

class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.child,
    required this.isActive,
    this.color = AppColors.glowAmber,
  });

  final Widget child;
  final bool isActive;
  final Color color;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => NeonGlow(
        isActive: true,
        color: widget.color,
        intensity: _pulse.value,
        child: widget.child,
      ),
    );
  }
}

// ── One-shot ripple on tap ────────────────────────────────────────────────────

class KeyRipple extends StatefulWidget {
  const KeyRipple({
    super.key,
    required this.trigger,   // increment this to fire a new ripple
    required this.color,
  });

  final int trigger;
  final Color color;

  @override
  State<KeyRipple> createState() => _KeyRippleState();
}

class _KeyRippleState extends State<KeyRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  int _lastTrigger = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale   = Tween<double>(begin: 0.0, end: 1.6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.55, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(KeyRipple old) {
    super.didUpdateWidget(old);
    if (widget.trigger != _lastTrigger) {
      _lastTrigger = widget.trigger;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.3),
          child: FractionallySizedBox(
            widthFactor: _scale.value,
            heightFactor: _scale.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: _opacity.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
