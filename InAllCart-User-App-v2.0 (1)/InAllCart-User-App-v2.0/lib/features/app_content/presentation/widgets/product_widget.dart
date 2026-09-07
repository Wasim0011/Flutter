import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/video_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/product_cards/grid_product_card.dart';
import '../../../../core/widgets/product_cards/horizontal_product_card.dart';
import '../../../../core/widgets/product_cards/large_product_card.dart';
import '../../domain/entities/app_content.dart';

class ProductContentWidget extends StatefulWidget {
  final AppContent content;
  final Function(ContentProduct product)? onProductTap;
  final VoidCallback? onViewAllTap;

  const ProductContentWidget({
    super.key,
    required this.content,
    this.onProductTap,
    this.onViewAllTap,
  });

  @override
  State<ProductContentWidget> createState() => _ProductContentWidgetState();
}

class _ProductContentWidgetState extends State<ProductContentWidget> {
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
  void didUpdateWidget(ProductContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.background?.mediaUrl !=
        widget.content.background?.mediaUrl) {
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
        if (mounted && _currentVideoUrl == url) {
          VideoCacheService().resumeController(url);
        }
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
    final products = widget.content.products ?? [];
    if (products.isEmpty) return const SizedBox.shrink();

    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.content.showTitle && widget.content.title != null ||
            widget.content.showViewAll && widget.onViewAllTap != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.content.showTitle && widget.content.title != null)
                Expanded(
                  child: Text(
                    widget.content.title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (widget.content.showViewAll && widget.onViewAllTap != null)
                GestureDetector(
                  onTap: widget.onViewAllTap,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (widget.content.showSubtitle && widget.content.subtitle != null) ...[
          Text(
            widget.content.subtitle!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
        ] else if (widget.content.showTitle && widget.content.title != null ||
            widget.content.showViewAll && widget.onViewAllTap != null) ...[
          const SizedBox(height: 8),
        ],
        _buildProductList(products),
      ],
    );

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
            Padding(padding: const EdgeInsets.all(16), child: contentWidget),
          ],
        );
      }

      contentWidget = Container(
        decoration: _buildBackgroundDecoration(),
        padding: const EdgeInsets.all(16),
        child: contentWidget,
      );
    } else {
      contentWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: contentWidget,
      );
    }

    return contentWidget;
  }

  BoxDecoration _buildBackgroundDecoration() {
    final background = widget.content.background;
    if (background == null || !background.enabled) return const BoxDecoration();

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

  Widget _buildProductList(List<ContentProduct> products) {
    final gridColumns = widget.content.gridColumns ?? 2;
    final gridRows = widget.content.gridRows ?? 2;
    final maxItems = widget.content.style == ContentStyle.style1
        ? gridColumns * gridRows
        : products.length;
    final hasMore = products.length > maxItems;
    final displayProducts = hasMore
        ? products.take(maxItems).toList()
        : products;

    switch (widget.content.style) {
      case ContentStyle.style1:
        return _buildGridStyle(displayProducts, gridColumns, hasMore);
      case ContentStyle.style2:
        return _buildHorizontalStyle(displayProducts);
      case ContentStyle.style3:
        return _buildLargeCardStyle(displayProducts);
      case ContentStyle.style4:
        return _buildGridStyle(displayProducts, gridColumns, hasMore);
    }
  }

  Widget _buildGridStyle(
    List<ContentProduct> products,
    int columns,
    bool hasMore,
  ) {
    final rows = widget.content.gridRows ?? 2;

    if (columns <= 3) {
      double aspectRatio;
      double crossAxisSpacing;
      double mainAxisSpacing;

      if (columns == 1) {
        aspectRatio = 0.75;
        crossAxisSpacing = 0;
        mainAxisSpacing = 12;
      } else if (columns == 2) {
        aspectRatio = 0.68;
        crossAxisSpacing = 8;
        mainAxisSpacing = 8;
      } else {
        aspectRatio = 0.60;
        crossAxisSpacing = 6;
        mainAxisSpacing = 6;
      }

      return Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                _buildProductCard(products[index], index),
          ),
        ],
      );
    }

    const double cardWidth = 130.0;
    const double cardHeight = 210.0;
    const double spacing = 8.0;

    return Column(
      children: [
        SizedBox(
          height: (cardHeight * rows) + (spacing * (rows - 1)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            addAutomaticKeepAlives: false,
            itemCount: (products.length / rows).ceil(),
            itemBuilder: (context, columnIndex) {
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: columnIndex < (products.length / rows).ceil() - 1
                      ? spacing
                      : 0,
                ),
                child: Column(
                  children: List.generate(rows, (rowIndex) {
                    final productIndex = columnIndex * rows + rowIndex;
                    if (productIndex >= products.length) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      height: cardHeight,
                      margin: EdgeInsets.only(
                        bottom: rowIndex < rows - 1 ? spacing : 0,
                      ),
                      child: _buildProductCard(
                        products[productIndex],
                        productIndex,
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalStyle(List<ContentProduct> products) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        addAutomaticKeepAlives: false,
        itemCount: products.length,
        itemBuilder: (context, index) => Container(
          width: 150,
          margin: EdgeInsets.only(right: index < products.length - 1 ? 10 : 0),
          child: _buildHorizontalProductCard(products[index], index),
        ),
      ),
    );
  }

  Widget _buildLargeCardStyle(List<ContentProduct> products) {
    return Column(
      children: products.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLargeProductCard(entry.value, entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildProductCard(ContentProduct product, int index) {
    final sectionPrefix =
        widget.content.title?.toLowerCase().replaceAll(' ', '_') ?? 'prod_sec';
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
      inStock: product.inStock,
      heroTag: uniqueHeroTag,
    );
  }

  Widget _buildHorizontalProductCard(ContentProduct product, int index) {
    final sectionPrefix =
        widget.content.title?.toLowerCase().replaceAll(' ', '_') ?? 'prod_sec';
    final uniqueHeroTag = 'sec_${sectionPrefix}_prod_${product.id}_$index';

    return HorizontalProductCard(
      productId: product.id,
      name: product.name,
      price: product.price,
      comparePrice: product.comparePrice,
      imageUrl: product.image,
      unit: product.unit,
      rating: product.rating,
      reviewCount: product.reviewCount,
      onTap: () => widget.onProductTap?.call(product),
      inStock: product.inStock,
      heroTag: uniqueHeroTag,
    );
  }

  Widget _buildLargeProductCard(ContentProduct product, int index) {
    final sectionPrefix =
        widget.content.title?.toLowerCase().replaceAll(' ', '_') ?? 'prod_sec';
    final uniqueHeroTag = 'sec_${sectionPrefix}_prod_${product.id}_$index';

    return LargeProductCard(
      productId: product.id,
      name: product.name,
      price: product.price,
      comparePrice: product.comparePrice,
      imageUrl: product.image,
      unit: product.unit,
      onTap: () => widget.onProductTap?.call(product),
      inStock: product.inStock,
      heroTag: uniqueHeroTag,
    );
  }
}
