import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/video_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_cards/circle_brand_card.dart';
import '../../../../core/widgets/brand_cards/grid_brand_card.dart';
import '../../../../core/widgets/brand_cards/banner_brand_card.dart';
import '../../domain/entities/app_content.dart';

class BrandContentWidget extends StatefulWidget {
  final AppContent content;
  final Function(int brandId)? onBrandTap;
  final VoidCallback? onViewAllTap;

  const BrandContentWidget({
    super.key,
    required this.content,
    this.onBrandTap,
    this.onViewAllTap,
  });

  @override
  State<BrandContentWidget> createState() => _BrandContentWidgetState();
}

class _BrandContentWidgetState extends State<BrandContentWidget> {
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
  void didUpdateWidget(BrandContentWidget oldWidget) {
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
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {
      // Invalid colour string — fall through to null and use the default.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.content.brands ?? [];
    if (brands.isEmpty) return const SizedBox.shrink();

    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.content.showTitle && widget.content.title != null) ...[
          Text(widget.content.title!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
        ],
        if (widget.content.showSubtitle && widget.content.subtitle != null) ...[
          Text(widget.content.subtitle!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
        ] else if (widget.content.showTitle && widget.content.title != null) ...[
          const SizedBox(height: 8),
        ],
        _buildBrandList(brands),
      ],
    );

    if (widget.content.background?.enabled == true) {
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
    final bg = widget.content.background;
    if (bg == null || !bg.enabled) return const BoxDecoration();
    switch (bg.type) {
      case BackgroundType.color:
        return BoxDecoration(
          color: _parseColor(bg.color) ?? AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        );
      case BackgroundType.image:
      case BackgroundType.gif:
        if (bg.mediaUrl != null) {
          return BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                  _getFullUrl(bg.mediaUrl!), maxWidth: 800, maxHeight: 800),
              fit: BoxFit.cover,
            ),
          );
        }
        return const BoxDecoration();
      case BackgroundType.video:
        return BoxDecoration(
            borderRadius: BorderRadius.circular(12), color: Colors.grey[200]);
      default:
        return const BoxDecoration();
    }
  }

  Widget _buildBrandList(List<ContentBrand> brands) {
    final gridColumns = widget.content.gridColumns ?? 3;
    final gridRows = widget.content.gridRows ?? 2;
    final maxItems = widget.content.style == ContentStyle.style2
        ? gridColumns * gridRows
        : brands.length;
    final hasMore = brands.length > maxItems;
    final displayBrands =
        hasMore ? brands.take(maxItems).toList() : brands;

    Widget brandWidget;
    switch (widget.content.style) {
      case ContentStyle.style1:
        brandWidget = _buildCircleStyle(displayBrands);
        break;
      case ContentStyle.style2:
        brandWidget = _buildCardGridStyle(displayBrands, gridColumns, hasMore);
        break;
      case ContentStyle.style3:
        brandWidget = _buildBannerStyle(displayBrands);
        break;
      case ContentStyle.style4:
        brandWidget = _buildCardGridStyle(displayBrands, gridColumns, hasMore);
        break;
    }

    if (widget.content.background?.enabled == true &&
        widget.content.background?.type == BackgroundType.video &&
        _videoController != null &&
        _isVideoInitialized) {
      return Stack(children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Video(
                controller: _videoController!,
                controls: NoVideoControls,
                fit: BoxFit.cover),
          ),
        ),
        brandWidget,
      ]);
    }

    return brandWidget;
  }

  Widget _buildCircleStyle(List<ContentBrand> brands) {
    if (widget.content.enableHorizontalAnimation) {
      return _AutoScrollingBrands(brands: brands, onBrandTap: widget.onBrandTap);
    }
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        addAutomaticKeepAlives: false,
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Padding(
            padding:
                EdgeInsets.only(right: index < brands.length - 1 ? 12 : 0),
            child: CircleBrandCard(
                brandId: brand.id,
                name: brand.name,
                logoUrl: brand.logo,
                onTap: () => widget.onBrandTap?.call(brand.id)),
          );
        },
      ),
    );
  }

  Widget _buildCardGridStyle(
      List<ContentBrand> brands, int columns, bool hasMore) {
    return Column(children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 1.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return GridBrandCard(
              brandId: brand.id,
              name: brand.name,
              logoUrl: brand.logo,
              onTap: () => widget.onBrandTap?.call(brand.id));
        },
      ),
      if (hasMore && widget.onViewAllTap != null) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onViewAllTap,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary)),
            child: const Text('View All'),
          ),
        ),
      ],
    ]);
  }

  Widget _buildBannerStyle(List<ContentBrand> brands) {
    if (widget.content.enableHorizontalAnimation) {
      return _AutoScrollingBrandBanners(
          brands: brands, onBrandTap: widget.onBrandTap);
    }
    return Column(
      children: brands.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < brands.length - 1 ? 10 : 0),
          child: BannerBrandCard(
              brandId: e.value.id,
              name: e.value.name,
              logoUrl: e.value.logo,
              onTap: () => widget.onBrandTap?.call(e.value.id)),
        );
      }).toList(),
    );
  }
}

class _AutoScrollingBrands extends StatefulWidget {
  final List<ContentBrand> brands;
  final Function(int brandId)? onBrandTap;
  const _AutoScrollingBrands({required this.brands, this.onBrandTap});

  @override
  State<_AutoScrollingBrands> createState() => _AutoScrollingBrandsState();
}

class _AutoScrollingBrandsState extends State<_AutoScrollingBrands> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.brands.length <= 3) return;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_isUserScrolling || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final next = _scrollController.offset + 0.5;
      _scrollController.jumpTo(next >= max ? 0 : next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _isUserScrolling = true;
          } else if (n is ScrollEndNotification) {
            Future.delayed(const Duration(seconds: 2),
                () { if (mounted) _isUserScrolling = false; });
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          addAutomaticKeepAlives: false,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.brands.length,
          itemBuilder: (context, index) {
            final brand = widget.brands[index];
            return Padding(
              padding: EdgeInsets.only(
                  right: index < widget.brands.length - 1 ? 12 : 0),
              child: CircleBrandCard(
                  brandId: brand.id,
                  name: brand.name,
                  logoUrl: brand.logo,
                  onTap: () => widget.onBrandTap?.call(brand.id)),
            );
          },
        ),
      ),
    );
  }
}

class _AutoScrollingBrandBanners extends StatefulWidget {
  final List<ContentBrand> brands;
  final Function(int brandId)? onBrandTap;
  const _AutoScrollingBrandBanners({required this.brands, this.onBrandTap});

  @override
  State<_AutoScrollingBrandBanners> createState() =>
      _AutoScrollingBrandBannersState();
}

class _AutoScrollingBrandBannersState
    extends State<_AutoScrollingBrandBanners> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.brands.length <= 2) return;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_isUserScrolling || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final next = _scrollController.offset + 0.5;
      _scrollController.jumpTo(next >= max ? 0 : next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _isUserScrolling = true;
          } else if (n is ScrollEndNotification) {
            Future.delayed(const Duration(seconds: 2),
                () { if (mounted) _isUserScrolling = false; });
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          addAutomaticKeepAlives: false,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.brands.length,
          itemBuilder: (context, index) {
            final brand = widget.brands[index];
            return Padding(
              padding: EdgeInsets.only(
                  right: index < widget.brands.length - 1 ? 12 : 0),
              child: BannerBrandCard(
                  brandId: brand.id,
                  name: brand.name,
                  logoUrl: brand.logo,
                  onTap: () => widget.onBrandTap?.call(brand.id)),
            );
          },
        ),
      ),
    );
  }
}
