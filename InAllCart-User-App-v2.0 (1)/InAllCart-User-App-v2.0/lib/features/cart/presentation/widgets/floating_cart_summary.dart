import 'dart:math' as math;
import '../../../../core/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/cart_bloc.dart';
import '../../domain/entities/cart.dart';

class FloatingCartSummary extends StatefulWidget {
  const FloatingCartSummary({super.key});

  @override
  State<FloatingCartSummary> createState() => _FloatingCartSummaryState();
}

class _FloatingCartSummaryState extends State<FloatingCartSummary> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  // High-End Shape Shifting Animations
  late Animation<double> _slideAnimation;      // Sink/Rise (0.0 - 0.3)
  late Animation<double> _widthAnimation;      // Ball to Pill (0.3 - 0.7)
  late Animation<double> _contentFadeAnimation; // Content Appearance (0.7 - 1.0)
  late Animation<double> _imageArrivalAnimation; // Images flying in (0.4 - 0.8)
  late Animation<double> _ballScalingAnimation; // Subtle pop for the "ball" stage
  
  // Removal Animation
  late AnimationController _removalController;
  late Animation<double> _removalFlyUpAnimation;
  late Animation<double> _removalDissolveAnimation;
  String? _removedImageUrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Deliberate speed
    );

    // 1. Sinking/Rising Phase (Bottom Nav Entrance/Exit)
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.0, 0.3, curve: Curves.easeInCubic),
      ),
    );

    // 2. Width Transformation (Ball -> Pill)
    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Content Visibility (Fade & Subtle Slide)
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // 4. Image Arrival (Staggered fly-in from right/top)
    _imageArrivalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // 5. Ball Pop (Subtle scale during the "ball" phase)
    _ballScalingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Removal Sequence
    _removalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _removalFlyUpAnimation = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(
        parent: _removalController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _removalDissolveAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _removalController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _removalController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _removedImageUrl = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _removalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state.cart.items.isNotEmpty) {
          if (_controller.status != AnimationStatus.completed && 
              _controller.status != AnimationStatus.forward) {
            _controller.forward();
          }
        } else {
          if (_controller.status != AnimationStatus.dismissed && 
              _controller.status != AnimationStatus.reverse) {
            _controller.reverse();
          }
        }
      },
      listenWhen: (previous, current) {
        // Trigger removal animation if an item was removed
        if (current.cart.items.length < previous.cart.items.length) {
          // Find the difference
          final removedItems = previous.cart.items.where(
            (p) => !current.cart.items.any((c) => c.productId == p.productId),
          );
          
          final CartItem? removedItem = removedItems.isNotEmpty 
              ? removedItems.first 
              : (previous.cart.items.isNotEmpty ? previous.cart.items.first : null);
          
          if (removedItem != null) {
            setState(() => _removedImageUrl = removedItem.productImage);
            _removalController.forward(from: 0.0);
          }
        }
        return true;
      },
      builder: (context, state) {
        final hasItems = state.cart.items.isNotEmpty;
        if (!hasItems && _controller.isDismissed) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Hide completely once the reverse animation finishes
            if (!hasItems && _controller.isDismissed) return const SizedBox.shrink();

            final screenWidth = MediaQuery.of(context).size.width;
            final maxPillWidth = screenWidth * 0.48; // Ultra-compact pill
            const minBallWidth = 60.0;
            
            // Calculate current width based on animated factor
            final currentWidth = minBallWidth + (maxPillWidth - minBallWidth) * _widthAnimation.value;
            
            // Fix: Positioned MUST be a child of a Stack.
            // Since FloatingCartSummary is used inside a Positioned(left:0, right:0) in the shell,
            // we wrap our internal Positioned in a Stack here.
            // We also wrap in a SizedBox with finite height to prevent "size.isFinite" errors.
            return SizedBox(
              width: screenWidth,
              height: 100, // Provides a finite bounds for the Stack
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: (screenWidth - currentWidth) / 2,
                    bottom: 24, // High enough to sink into bottom nav
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 80), // Sink effect
                      child: Opacity(
                        opacity: (1.0 - (_slideAnimation.value * 0.5)).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: _controller.value < 0.4 ? _ballScalingAnimation.value : 1.0,
                          child: _buildPill(context, state, currentWidth),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPill(BuildContext context, CartState state, double width) {
    final showContent = _controller.value > 0.7;

    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.cart),
      child: Container(
        width: width,
        height: 54, // Reduced from 60
        padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced from 10
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100), // Ball to Pill
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Removal Animation Overlay (Flying Up)
            if (_removedImageUrl != null)
              AnimatedBuilder(
                animation: _removalController,
                builder: (context, child) {
                  final jitter = math.sin(_removalController.value * 100) * 3.0 * (1.0 - _removalDissolveAnimation.value);
                  return Positioned(
                    left: 2 + jitter,
                    child: Transform.translate(
                      offset: Offset(0, _removalFlyUpAnimation.value),
                      child: Transform.scale(
                        scale: _removalDissolveAnimation.value,
                        child: Transform.rotate(
                          angle: (1.0 - _removalDissolveAnimation.value) * 0.2, // Slight twist
                          child: Opacity(
                            opacity: _removalDissolveAnimation.value,
                            child: _buildCircluarImage(_removedImageUrl!),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Always show current images
            Positioned(
              left: 2,
              child: _buildImagesStack(state),
            ),

            // Content appearing in the middle
            if (showContent)
              Opacity(
                opacity: _contentFadeAnimation.value.clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(left: 54, right: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'View cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        '${state.cart.summary.itemsCount} items',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Trailing Chevron
            if (showContent)
              Positioned(
                right: 8,
                child: Opacity(
                  opacity: _contentFadeAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            
            // Just the bag icon when it's a "ball"
            if (_controller.value < 0.4)
              const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesStack(CartState state) {
    final images = state.cart.items
        .where((item) => item.productImage != null)
        .map((item) => item.productImage!)
        .take(4)
        .toList();
    
    if (images.isEmpty) return const SizedBox.shrink();

    // Progressive offsets for a modern Premium look (10/20/30/100 visibility)
    const offsets = [0.0, 4.0, 11.0, 24.0];
    final maxOffset = offsets[math.min(images.length - 1, 3)];

    return SizedBox(
      height: 40,
      width: 38 + maxOffset,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: List.generate(images.length, (index) {
          // Arrival animation: Fly in from top-right
          return Positioned(
            left: offsets[index],
            child: Transform.translate(
              offset: Offset(
                (1.0 - _imageArrivalAnimation.value) * 100, // Fly from right
                (1.0 - _imageArrivalAnimation.value) * -50, // Fly from top
              ),
              child: Opacity(
                opacity: _imageArrivalAnimation.value.clamp(0.0, 1.0),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: ClipOval(
                    child: CachedImage(
                      imageUrl: AppConstants.getFullMediaUrl(images[index]),
                      fit: BoxFit.cover,
                      errorWidget: const Icon(Icons.image, size: 12),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCircluarImage(String imageUrl) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
        child: CachedImage(
          imageUrl: AppConstants.getFullMediaUrl(imageUrl),
          fit: BoxFit.cover,
          errorWidget: const Icon(Icons.image, size: 12),
        ),
      ),
    );
  }
}
