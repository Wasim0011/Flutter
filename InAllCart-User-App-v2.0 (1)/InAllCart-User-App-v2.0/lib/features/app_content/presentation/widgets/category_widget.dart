import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/video_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/product_cards/grid_product_card.dart';
import '../../../../core/widgets/category_cards/circle_category_card.dart';
import '../../../../core/widgets/category_cards/grid_category_card.dart';
import '../../domain/entities/app_content.dart';

class CategoryContentWidget extends StatefulWidget {
  final AppContent content;
  final Function(int categoryId)? onCategoryTap;
  final Function(ContentProduct product)? onProductTap;
  final VoidCallback? onViewAllTap;

  const CategoryContentWidget({
    super.key,
    required this.content,
    this.onCategoryTap,
    this.onProductTap,
    this.onViewAllTap,
  });

  @override
  State<CategoryContentWidget> createState() => _CategoryContentWidgetState();
}

class _CategoryContentWidgetState extends State<CategoryContentWidget> {
  VideoController? _videoController;
  bool _isVideoInitialized = false;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startBackgroundVideo();
    });
  }

  @override
  void didUpdateWidget(CategoryContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.background?.mediaUrl != widget.content.background?.mediaUrl) {
      _disposeVideo();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startBackgroundVideo();
      });
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    if (_currentVideoUrl != null) {
      VideoCacheService().releaseController(_currentVideoUrl!);
      _videoController = null;
      _currentVideoUrl = null;
      _isVideoInitialized = false;
    }
  }

  void _startBackgroundVideo() {
    if (widget.content.background?.enabled != true ||
        widget.content.background?.type != BackgroundType.video ||
        widget.content.background?.mediaUrl == null) {
      return;
    }

    final url = _getFullUrl(widget.content.background!.mediaUrl!);
    _currentVideoUrl = url;

    final entry = VideoCacheService().createController(url, priority: 0);
    if (entry == null) return;

    setState(() => _videoController = entry.controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentVideoUrl != url) return;
      setState(() => _isVideoInitialized = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentVideoUrl == url) VideoCacheService().resumeController(url);
      });
    });
  }

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return AppConstants.getFullMediaUrl(url);
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;
    try {
      final hex = colorStr.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      // Invalid colour string — fall through to null and use the default.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.content.categories ?? [];
    if (categories.isEmpty) return const SizedBox.shrink();

    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.content.showTitle && widget.content.title != null) ...[
          Text(
            widget.content.title!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.content.showSubtitle && widget.content.subtitle != null)
            const SizedBox(height: 4)
          else
            const SizedBox(height: 4),
        ],
        if (widget.content.showSubtitle && widget.content.subtitle != null) ...[
          Text(
            widget.content.subtitle!,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
        _buildCategoryList(categories),
      ],
    );

    // Apply background if enabled
    if (widget.content.background?.enabled == true) {
      if (widget.content.background?.type == BackgroundType.video &&
          _videoController != null &&
          _isVideoInitialized) {
        return Stack(
          children: [
            Positioned.fill(
              child: Video(
                controller: _videoController!,
                controls: NoVideoControls,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: contentWidget,
            ),
          ],
        );
      }

      contentWidget = Container(
        decoration: _buildBackgroundDecoration(),
        padding: const EdgeInsets.all(16),
        child: contentWidget,
      );
    } else {
      final horizontalPadding = widget.content.style == ContentStyle.style4 ? 12.0 : 16.0;
      contentWidget = Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: contentWidget,
      );
    }

    return contentWidget;
  }

  BoxDecoration _buildBackgroundDecoration() {
    final background = widget.content.background;
    if (background == null || !background.enabled) {
      return const BoxDecoration();
    }

    switch (background.type) {
      case BackgroundType.color:
        return BoxDecoration(
          color: _parseColor(background.color) ?? AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        );
      case BackgroundType.image:
      case BackgroundType.gif:
        if (background.mediaUrl != null) {
          return BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                _getFullUrl(background.mediaUrl!),
                maxWidth: 800,
                maxHeight: 800,
              ),
              fit: BoxFit.cover,
            ),
          );
        }
        return const BoxDecoration();
      case BackgroundType.video:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        );
      default:
        return const BoxDecoration();
    }
  }

  Widget _buildCategoryList(List<ContentCategory> categories) {
    final gridColumns = widget.content.gridColumns ?? 3;
    final gridRows = widget.content.gridRows ?? 2;

    int maxItems;
    if (widget.content.style == ContentStyle.style2) {
      maxItems = gridColumns * gridRows;
    } else if (widget.content.style == ContentStyle.style4) {
      if (gridRows == 1) {
        maxItems = 3;
      } else {
        maxItems = 3 + ((gridRows - 1) * 4);
      }
    } else {
      maxItems = categories.length;
    }

    final displayCategories = categories.length > maxItems
        ? categories.take(maxItems).toList()
        : categories;

    switch (widget.content.style) {
      case ContentStyle.style1:
        return _buildCircleStyle(displayCategories);
      case ContentStyle.style2:
        return _buildCardGridStyle(displayCategories, gridColumns);
      case ContentStyle.style3:
        return _buildBannerStyle(displayCategories);
      case ContentStyle.style4:
        return _buildCheckmarkStyle(displayCategories);
    }
  }

  Widget _buildCircleStyle(List<ContentCategory> categories) {
    return SizedBox(
      height: 124,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: EdgeInsets.only(right: index < categories.length - 1 ? 12 : 0),
            child: CircleCategoryCard(
              categoryId: category.id,
              name: category.name,
              imageUrl: category.image,
              onTap: () => widget.onCategoryTap?.call(category.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardGridStyle(List<ContentCategory> categories, int columns) {
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (columns <= 2) {
      crossAxisSpacing = 12;
      mainAxisSpacing = 8;
    } else if (columns == 3) {
      crossAxisSpacing = 10;
      mainAxisSpacing = 6;
    } else {
      crossAxisSpacing = 8;
      mainAxisSpacing = 4;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((columns - 1) * crossAxisSpacing)) / columns;
        final itemHeight = itemWidth + 26;
        final aspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GridCategoryCard(
              categoryId: category.id,
              name: category.name,
              imageUrl: category.image,
              onTap: () => widget.onCategoryTap?.call(category.id),
            );
          },
        );
      },
    );
  }

  Widget _buildBannerStyle(List<ContentCategory> categories) {
    return _CategoryTabsWithProducts(
      categories: categories,
      onCategoryTap: widget.onCategoryTap,
      onProductTap: widget.onProductTap,
      enableAnimation: widget.content.enableHorizontalAnimation,
    );
  }

  Widget _buildCheckmarkStyle(List<ContentCategory> categories) {
    return _CheckmarkGrid(
      categories: categories,
      onCategoryTap: widget.onCategoryTap,
    );
  }
}

// Style 3: Category tabs with products below
class _CategoryTabsWithProducts extends StatefulWidget {
  final List<ContentCategory> categories;
  final Function(int categoryId)? onCategoryTap;
  final Function(ContentProduct product)? onProductTap;
  final bool enableAnimation;

  const _CategoryTabsWithProducts({
    required this.categories,
    this.onCategoryTap,
    this.onProductTap,
    this.enableAnimation = false,
  });

  @override
  State<_CategoryTabsWithProducts> createState() => _CategoryTabsWithProductsState();
}

class _CategoryTabsWithProductsState extends State<_CategoryTabsWithProducts> {
  int _selectedCategoryIndex = 0;
  ScrollController? _productsScrollController;
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableAnimation) {
      _productsScrollController = ScrollController();
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _productsScrollController?.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    final products = widget.categories[_selectedCategoryIndex].products ?? [];
    if (products.length <= 2) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_isUserScrolling ||
          _productsScrollController == null ||
          !_productsScrollController!.hasClients) {
        return;
      }

      final maxScroll = _productsScrollController!.position.maxScrollExtent;
      final currentScroll = _productsScrollController!.offset;
      final newOffset = currentScroll + 0.8;

      if (newOffset >= maxScroll) {
        _productsScrollController!.jumpTo(0);
      } else {
        _productsScrollController!.jumpTo(newOffset);
      }
    });
  }

  void _onScrollStart() => _isUserScrolling = true;

  void _onScrollEnd() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _isUserScrolling = false;
    });
  }

  void _onCategoryChanged(int index) {
    setState(() => _selectedCategoryIndex = index);
    _autoScrollTimer?.cancel();
    if (_productsScrollController != null && _productsScrollController!.hasClients) {
      _productsScrollController!.jumpTo(0);
    }
    if (widget.enableAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories[_selectedCategoryIndex];
    final products = selectedCategory.products ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 124,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final isSelected = _selectedCategoryIndex == index;

              return Padding(
                padding: EdgeInsets.only(right: index < widget.categories.length - 1 ? 16 : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleCategoryCard(
                      categoryId: category.id,
                      name: category.name,
                      imageUrl: category.image,
                      onTap: () => _onCategoryChanged(index),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No products available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: widget.enableAnimation
                ? NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification && notification.dragDetails != null) {
                        _onScrollStart();
                      } else if (notification is ScrollEndNotification) {
                        _onScrollEnd();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _productsScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      cacheExtent: 500,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Container(
                          width: 140,
                          margin: EdgeInsets.only(right: index < products.length - 1 ? 10 : 0),
                          child: _buildProductCard(product, index),
                        );
                      },
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    cacheExtent: 500,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
                        width: 140,
                        margin: EdgeInsets.only(right: index < products.length - 1 ? 10 : 0),
                        child: _buildProductCard(product, index),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildProductCard(ContentProduct product, int index) {
    final selectedCategory = widget.categories[_selectedCategoryIndex];
    final sectionPrefix = selectedCategory.name.toLowerCase().replaceAll(' ', '_');
    final uniqueHeroTag = 'sec_${sectionPrefix}_prod_${product.id}_$index';

    return GridProductCard(
      productId: product.id,
      name: product.name,
      price: product.price,
      comparePrice: product.comparePrice,
      imageUrl: product.image,
      unit: product.unit,
      rating: product.rating,
      reviewCount: product.reviewCount,
                      onTap: () => widget.onProductTap?.call(product),
      inStock: true,
      heroTag: uniqueHeroTag,
    );
  }
}

// Style 4: Premium FIXED GRID
class _CheckmarkGrid extends StatelessWidget {
  final List<ContentCategory> categories;
  final Function(int categoryId)? onCategoryTap;

  const _CheckmarkGrid({
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width - 24;
    final gap = 6.0;
    final boxSize = (screenWidth - (3 * gap)) / 4.3;

    final rows = <Widget>[];
    int index = 0;

    if (categories.isNotEmpty) {
      rows.add(_buildFirstRow(categories, boxSize, gap));
      index = categories.length >= 3 ? 3 : categories.length;
      if (index < categories.length) rows.add(SizedBox(height: gap));
    }

    while (index < categories.length) {
      final rowCategories = categories.skip(index).take(4).toList();
      if (rowCategories.isEmpty) break;
      rows.add(_buildSquareRow(rowCategories, boxSize, gap));
      index += 4;
      if (index < categories.length) rows.add(SizedBox(height: gap));
    }

    return Column(children: rows);
  }

  Widget _buildFirstRow(List<ContentCategory> categories, double boxSize, double gap) {
    final first = categories[0];
    final hasSecond = categories.length > 1;
    final hasThird = categories.length > 2;
    final rowHeight = boxSize * 1.5;

    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(height: rowHeight, child: _buildLargeCard(first)),
          ),
          SizedBox(width: gap),
          if (hasSecond)
            SizedBox(width: boxSize, height: rowHeight, child: _buildSmallCard(categories[1])),
          if (hasSecond && hasThird) SizedBox(width: gap),
          if (hasThird)
            SizedBox(width: boxSize, height: rowHeight, child: _buildSmallCard(categories[2])),
        ],
      ),
    );
  }

  Widget _buildSquareRow(List<ContentCategory> categories, double boxSize, double gap) {
    final rowHeight = boxSize * 1.5;
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: List.generate(
          categories.length * 2 - 1,
          (index) {
            if (index.isOdd) return SizedBox(width: gap);
            final catIndex = index ~/ 2;
            return SizedBox(
              width: boxSize,
              height: rowHeight,
              child: _buildSmallCard(categories[catIndex]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLargeCard(ContentCategory category) {
    return GestureDetector(
      onTap: () => onCategoryTap?.call(category.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: AppColors.surfaceLight,
                child: LayoutBuilder(
                  builder: (context, constraints) => _buildCategoryImage(
                    category.image,
                    width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
                    height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard(ContentCategory category) {
    return GestureDetector(
      onTap: () => onCategoryTap?.call(category.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: AppColors.surfaceLight,
                child: LayoutBuilder(
                  builder: (context, constraints) => _buildCategoryImage(
                    category.image,
                    width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
                    height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl, {double? width, double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover);
    }
    final fullUrl = imageUrl.startsWith('http') ? imageUrl : AppConstants.getFullMediaUrl(imageUrl);
    return CachedImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorWidget: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
    );
  }
}
