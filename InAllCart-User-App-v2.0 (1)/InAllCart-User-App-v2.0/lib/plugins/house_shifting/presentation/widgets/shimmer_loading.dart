import 'package:flutter/material.dart';

/// Shimmer loading placeholder for the House Shifting screen.
class ShiftingShimmer extends StatefulWidget {
  const ShiftingShimmer({super.key});

  @override
  State<ShiftingShimmer> createState() => _ShiftingShimmerState();
}

class _ShiftingShimmerState extends State<ShiftingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(height: 140, radius: 20),
              const SizedBox(height: 16),
              _shimmerBox(height: 100, radius: 16),
              const SizedBox(height: 20),
              _shimmerBox(height: 18, width: 160, radius: 4),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _shimmerBox(height: 56, radius: 14)),
                  const SizedBox(width: 10),
                  Expanded(child: _shimmerBox(height: 56, radius: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _shimmerBox(height: 56, radius: 14)),
                  const SizedBox(width: 10),
                  Expanded(child: _shimmerBox(height: 56, radius: 14)),
                ],
              ),
              const SizedBox(height: 20),
              _shimmerBox(height: 18, width: 140, radius: 4),
              const SizedBox(height: 12),
              _shimmerBox(height: 80, radius: 16),
              const SizedBox(height: 10),
              _shimmerBox(height: 80, radius: 16),
              const SizedBox(height: 10),
              _shimmerBox(height: 80, radius: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: const [
            Color(0xFFEEEEEE),
            Color(0xFFF5F5F5),
            Color(0xFFEEEEEE),
          ],
        ),
      ),
    );
  }
}

/// AnimatedBuilder that rebuilds on each tick of a [Listenable].
class AnimatedBuilder extends StatelessWidget {
  final Listenable listenable;
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: listenable, builder: builder);
  }
}
