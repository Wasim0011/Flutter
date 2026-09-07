import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Professional Premium-style loader
/// Uses a pulsing/shimmering logo effect instead of a boring spinner
class InAllCartLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final bool useOverlay;

  const InAllCartLoader({
    super.key,
    this.size = 48,
    this.color,
    this.useOverlay = false,
  });

  @override
  State<InAllCartLoader> createState() => _InAllCartLoaderState();
}

class _InAllCartLoaderState extends State<InAllCartLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLoader() {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: (widget.color ?? AppColors.primary).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring pulsing
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (widget.color ?? AppColors.primary).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  // Inner solid pulsing
                  Container(
                    width: widget.size * 0.4,
                    height: widget.size * 0.4,
                    decoration: BoxDecoration(
                      color: widget.color ?? AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useOverlay) {
      return Stack(
        children: [
          Container(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          _buildLoader(),
        ],
      );
    }
    return _buildLoader();
  }
}
