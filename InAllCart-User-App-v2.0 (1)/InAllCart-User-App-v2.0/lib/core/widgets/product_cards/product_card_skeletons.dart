import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../adaptive_product_card.dart';

/// Base Shimmer Widget configuration
class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer Skeleton for [HorizontalProductCard]
/// Fixed width: 150px
class HorizontalProductCardSkeleton extends StatelessWidget {
  const HorizontalProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (AspectRatio 1.0)
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    right: 2,
                    child: const _ShimmerBlock(width: 60, height: 26, borderRadius: 6),
                  ),
                ],
              ),
            ),
            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating / Delivery badges
                    Row(
                      children: [
                        const _ShimmerBlock(width: 40, height: 14),
                        const SizedBox(width: 4),
                        const _ShimmerBlock(width: 50, height: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title Lines
                    const _ShimmerBlock(width: 120, height: 12),
                    const SizedBox(height: 4),
                    const _ShimmerBlock(width: 80, height: 12),
                    const SizedBox(height: 6),
                    // Unit text
                    const _ShimmerBlock(width: 40, height: 10),
                    const Spacer(),
                    // Price Row (Button removed from here)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ShimmerBlock(width: 50, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer Skeleton for [GridProductCard]
/// Flexible width based on Grid - Matches GridProductCard flex layout
class GridProductCardSkeleton extends StatelessWidget {
  final bool isLargeCard;
  
  const GridProductCardSkeleton({
    super.key, 
    this.isLargeCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (flex: 5) - Matches GridProductCard
            Expanded(
              flex: 5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Discount Badge (top-left)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 36,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Wishlist Icon (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Add Button (bottom-right, overlapping)
                  Positioned(
                    bottom: -10,
                    right: 2,
                    child: Container(
                      width: isLargeCard ? 65 : 55,
                      height: isLargeCard ? 28 : 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details Section (flex: 4) - Matches GridProductCard
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating Badge
                    Container(
                      width: 45,
                      height: isLargeCard ? 16 : 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title Line 1
                    Container(
                      width: double.infinity,
                      height: isLargeCard ? 14 : 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title Line 2
                    Container(
                      width: 80,
                      height: isLargeCard ? 14 : 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Unit
                    Container(
                      width: 40,
                      height: isLargeCard ? 11 : 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    // Price Row
                    Row(
                      children: [
                        Container(
                          width: isLargeCard ? 70 : 55,
                          height: isLargeCard ? 14 : 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 35,
                          height: isLargeCard ? 11 : 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Shimmer Skeleton for [LargeProductCard]
/// Fixed Height: 120px
class LargeProductCardSkeleton extends StatelessWidget {
  const LargeProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            // Image (120x120)
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating
                    const _ShimmerBlock(width: 50, height: 16),
                    const SizedBox(height: 8),
                    // Price Row (Green container match)
                    const Row(
                      children: [
                        _ShimmerBlock(width: 70, height: 28), // Matches container height
                        SizedBox(width: 8),
                        _ShimmerBlock(width: 40, height: 14),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    const _ShimmerBlock(width: 150, height: 16),
                    const SizedBox(height: 4),
                    const _ShimmerBlock(width: 80, height: 12),
                    const Spacer(),
                    // Unit
                    const _ShimmerBlock(width: 40, height: 12),
                  ],
                ),
              ),
            ),
            // Add Button
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: _ShimmerBlock(width: 40, height: 40, borderRadius: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adaptive Skeleton that switches based on size/context
class AdaptiveProductCardSkeleton extends StatelessWidget {
  final ProductCardSize? cardSize;
  final double width;

  const AdaptiveProductCardSkeleton({
    super.key,
    this.cardSize,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final size = cardSize ?? _detectSize(width);

    switch (size) {
      case ProductCardSize.xs:
      case ProductCardSize.small:
      case ProductCardSize.medium:
        return GridProductCardSkeleton(
          isLargeCard: size == ProductCardSize.medium,
        );
      case ProductCardSize.large:
        // Check if width allows for horizontal layout
        if (width >= 300) {
          return const LargeProductCardSkeleton();
        }
        return const GridProductCardSkeleton(isLargeCard: true);
    }
  }

  ProductCardSize _detectSize(double width) {
    if (width < 120) return ProductCardSize.xs;
    if (width < 140) return ProductCardSize.small;
    if (width < 180) return ProductCardSize.medium;
    return ProductCardSize.large;
  }
}
