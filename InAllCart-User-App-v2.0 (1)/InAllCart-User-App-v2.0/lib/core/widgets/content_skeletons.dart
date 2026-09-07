import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// ==========================================
/// DYNAMIC CONTENT SKELETON WIDGETS
/// ==========================================
/// Skeleton widgets that match actual widget configurations
/// Shimmer applied to individual card elements, not entire sections

// ==========================================
// PRODUCT CONTENT SKELETON
// ==========================================

/// Product Content Skeleton - matches ProductContentWidget
/// Supports: Style 1 (Grid), Style 2 (Horizontal), Style 3 (Large cards)
class ProductContentSkeleton extends StatelessWidget {
  final int style; // 1: Grid, 2: Horizontal, 3: Large
  final int gridColumns;
  final int gridRows;
  final double? height;
  final bool showTitle;
  final bool showSubtitle;
  final bool hasBackground;

  const ProductContentSkeleton({
    super.key,
    this.style = 1,
    this.gridColumns = 2,
    this.gridRows = 2,
    this.height,
    this.showTitle = true,
    this.showSubtitle = false,
    this.hasBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          const _ShimmerTitle(),
          if (showSubtitle) const SizedBox(height: 4),
        ],
        if (showSubtitle) ...[
          const _ShimmerSubtitle(),
          const SizedBox(height: 12),
        ] else if (showTitle) ...[
          const SizedBox(height: 8),
        ],
        _buildProductsSkeleton(context),
      ],
    );

    if (hasBackground) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }

  Widget _buildProductsSkeleton(BuildContext context) {
    switch (style) {
      case 1: // Grid style
        return _buildGridStyle();
      case 2: // Horizontal scroll style
        return _buildHorizontalStyle();
      case 3: // Large cards style
        return _buildLargeCardStyle();
      default:
        return _buildGridStyle();
    }
  }

  Widget _buildGridStyle() {
    double aspectRatio;
    double spacing;
    
    if (gridColumns == 1) {
      aspectRatio = 0.75;
      spacing = 12;
    } else if (gridColumns == 2) {
      aspectRatio = 0.68;
      spacing = 8;
    } else {
      aspectRatio = 0.60;
      spacing = 6;
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: gridColumns * gridRows,
      itemBuilder: (_, __) => GridProductCardSkeleton(isLargeCard: gridColumns <= 2),
    );
  }

  Widget _buildHorizontalStyle() {
    return SizedBox(
      height: height ?? 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => const HorizontalProductCardSkeleton(),
      ),
    );
  }

  Widget _buildLargeCardStyle() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const LargeProductCardSkeleton(),
    );
  }
}

// ==========================================
// CATEGORY CONTENT SKELETON
// ==========================================

/// Category Content Skeleton - matches CategoryContentWidget
class CategoryContentSkeleton extends StatelessWidget {
  final int style; // 1: Circle, 2: Grid, 3: Tabs, 4: Checkmark
  final int gridColumns;
  final int gridRows;
  final bool showTitle;
  final bool showSubtitle;
  final bool hasBackground;

  const CategoryContentSkeleton({
    super.key,
    this.style = 1,
    this.gridColumns = 3,
    this.gridRows = 2,
    this.showTitle = true,
    this.showSubtitle = false,
    this.hasBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          const _ShimmerTitle(),
          const SizedBox(height: 8),
        ],
        if (showSubtitle) ...[
          const _ShimmerSubtitle(),
          const SizedBox(height: 8),
        ],
        _buildCategoriesSkeleton(context),
      ],
    );

    final horizontalPadding = style == 4 ? 12.0 : 16.0;
    
    if (hasBackground) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: content,
    );
  }

  Widget _buildCategoriesSkeleton(BuildContext context) {
    switch (style) {
      case 1:
        return _buildCircleStyle();
      case 2:
        return _buildGridStyle();
      case 3:
        return _buildTabsStyle();
      case 4:
        return _buildCheckmarkStyle(context);
      default:
        return _buildCircleStyle();
    }
  }

  Widget _buildCircleStyle() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const CircleCategoryCardSkeleton(),
      ),
    );
  }

  Widget _buildGridStyle() {
    double aspectRatio = gridColumns <= 2 ? 0.75 : (gridColumns == 3 ? 0.72 : 0.72);
    double spacing = gridColumns <= 2 ? 12 : (gridColumns == 3 ? 10 : 8);

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: gridColumns * gridRows,
      itemBuilder: (_, __) => const GridCategoryCardSkeleton(),
    );
  }

  Widget _buildTabsStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, index) => const CircleCategoryCardSkeleton(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => SizedBox(
              width: 140,
              child: GridProductCardSkeleton(isLargeCard: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckmarkStyle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 24;
    final gap = 6.0;
    final boxSize = (screenWidth - (3 * gap)) / 4.3;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          SizedBox(
            height: boxSize,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: boxSize * 1.3,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: gap),
                Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(width: gap),
                Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          for (int row = 0; row < gridRows - 1; row++) ...[
            SizedBox(
              height: boxSize,
              child: Row(
                children: List.generate(4, (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 3 ? gap : 0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )),
              ),
            ),
            if (row < gridRows - 2) SizedBox(height: gap),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// BRAND CONTENT SKELETON
// ==========================================

/// Brand Content Skeleton - matches BrandContentWidget
class BrandContentSkeleton extends StatelessWidget {
  final int style; // 1: Circle, 2: Grid, 3: Banner
  final int gridColumns;
  final int gridRows;
  final bool showTitle;
  final bool showSubtitle;
  final bool hasBackground;

  const BrandContentSkeleton({
    super.key,
    this.style = 1,
    this.gridColumns = 3,
    this.gridRows = 2,
    this.showTitle = true,
    this.showSubtitle = false,
    this.hasBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const _ShimmerTitle(),
          const SizedBox(height: 8),
        ],
        if (showSubtitle) ...[
          const _ShimmerSubtitle(),
          const SizedBox(height: 8),
        ],
        _buildBrandsSkeleton(),
      ],
    );

    if (hasBackground) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }

  Widget _buildBrandsSkeleton() {
    switch (style) {
      case 1:
        return _buildCircleStyle();
      case 2:
        return _buildGridStyle();
      case 3:
        return _buildBannerStyle();
      default:
        return _buildCircleStyle();
    }
  }

  Widget _buildCircleStyle() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const CircleBrandCardSkeleton(),
      ),
    );
  }

  Widget _buildGridStyle() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        childAspectRatio: 1.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: gridColumns * gridRows,
      itemBuilder: (_, __) => const GridBrandCardSkeleton(),
    );
  }

  Widget _buildBannerStyle() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const BannerBrandCardSkeleton(),
      ),
    );
  }
}

// ==========================================
// MEDIA CONTENT SKELETON
// ==========================================

/// Media Content Skeleton - matches MediaContentWidget
class MediaContentSkeleton extends StatelessWidget {
  final int style; // 1: FullWidth, 2: Padded, 3: Rounded
  final double? height;
  final bool showTitle;
  final bool showSubtitle;

  const MediaContentSkeleton({
    super.key,
    this.style = 1,
    this.height,
    this.showTitle = false,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle || showSubtitle) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTitle) Container(
                    width: 180,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
          _buildMediaSkeleton(),
        ],
      ),
    );
  }

  Widget _buildMediaSkeleton() {
    final mediaHeight = height ?? 180.0;
    
    switch (style) {
      case 1: // Full width
        return Container(
          width: double.infinity,
          height: mediaHeight,
          color: Colors.white,
        );
      case 2: // Padded
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          height: mediaHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case 3: // Rounded
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          height: mediaHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      default:
        return Container(
          width: double.infinity,
          height: mediaHeight,
          color: Colors.white,
        );
    }
  }
}

// ==========================================
// INDIVIDUAL CARD SKELETONS WITH SHIMMER
// ==========================================

/// Grid Product Card Skeleton - matches GridProductCard (flex 5:4)
class GridProductCardSkeleton extends StatelessWidget {
  final bool isLargeCard;
  
  const GridProductCardSkeleton({super.key, this.isLargeCard = false});

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
          children: [
            // Image Section (flex: 5)
            Expanded(
              flex: 5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Image background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Discount badge (top-left)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 36,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Add button (bottom-right, overlapping)
                  Positioned(
                    bottom: -10,
                    right: 2,
                    child: Container(
                      width: isLargeCard ? 65 : 55,
                      height: isLargeCard ? 28 : 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details Section (flex: 4)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating badge
                    Container(
                      width: 45,
                      height: isLargeCard ? 16 : 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title line 1
                    Container(
                      width: double.infinity,
                      height: isLargeCard ? 14 : 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title line 2
                    Container(
                      width: 80,
                      height: isLargeCard ? 14 : 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Unit
                    Container(
                      width: 40,
                      height: isLargeCard ? 11 : 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    // Price row
                    Row(
                      children: [
                        Container(
                          width: isLargeCard ? 70 : 55,
                          height: isLargeCard ? 14 : 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 35,
                          height: isLargeCard ? 11 : 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
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

/// Horizontal Product Card Skeleton - matches HorizontalProductCard (width: 150)
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
                  // Discount badge
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 32,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  // Add button
                  Positioned(
                    bottom: -10,
                    right: 2,
                    child: Container(
                      width: 55,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
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
                    // Title line 1
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title line 2
                    Container(
                      width: 70,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Unit
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    // Price
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
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

/// Large Product Card Skeleton - matches LargeProductCard (height: 120)
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Image (120x120)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating badge
                    Container(
                      width: 50,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price row
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    // Unit
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Add button
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circle Category Card Skeleton - matches CircleCategoryCard (width: 80, circle: 70)
class CircleCategoryCardSkeleton extends StatelessWidget {
  const CircleCategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle image (65x65)
            Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Name line 1
            Container(
              width: 60,
              height: 11,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),
            // Name line 2
            Container(
              width: 45,
              height: 11,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid Category Card Skeleton - matches GridCategoryCard (AspectRatio 1.0)
class GridCategoryCardSkeleton extends StatelessWidget {
  const GridCategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          // Image (Expanded with AspectRatio 1.0)
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Category name
          Container(
            width: 50,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circle Brand Card Skeleton - matches CircleBrandCard (width: 80, circle: 70 with border)
class CircleBrandCardSkeleton extends StatelessWidget {
  const CircleBrandCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle logo (65x65 with border effect)
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Name line 1
            Container(
              width: 55,
              height: 11,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),
            // Name line 2
            Container(
              width: 40,
              height: 11,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid Brand Card Skeleton - matches GridBrandCard (white with border)
class GridBrandCardSkeleton extends StatelessWidget {
  const GridBrandCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          children: [
            // Logo area (Expanded with padding 16)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // Brand name
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner Brand Card Skeleton - matches BannerBrandCard (height: 100)
class BannerBrandCardSkeleton extends StatelessWidget {
  const BannerBrandCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Center(
          child: Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HELPER WIDGETS
// ==========================================

/// Shimmer Title Widget
class _ShimmerTitle extends StatelessWidget {
  const _ShimmerTitle();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 180,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer Subtitle Widget
class _ShimmerSubtitle extends StatelessWidget {
  const _ShimmerSubtitle();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 120,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ==========================================
// LEGACY EXPORTS (backward compatibility)
// ==========================================

class FullWidthMediaSkeleton extends StatelessWidget {
  final double height;
  const FullWidthMediaSkeleton({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) => MediaContentSkeleton(style: 1, height: height);
}

class CircleCategorySkeleton extends StatelessWidget {
  const CircleCategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) => const CategoryContentSkeleton(style: 1, showTitle: false);
}

class CircleBrandSkeleton extends StatelessWidget {
  const CircleBrandSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const BrandContentSkeleton(style: 1, showTitle: false);
}

class SectionTitleSkeleton extends StatelessWidget {
  final bool showSubtitle;
  final bool hasBackground;
  
  const SectionTitleSkeleton({super.key, this.showSubtitle = false, this.hasBackground = false});

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShimmerTitle(),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          const _ShimmerSubtitle(),
        ],
      ],
    );

    if (hasBackground) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: content,
    );
  }
}
