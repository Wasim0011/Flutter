import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/video_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../domain/entities/app_content.dart';
import 'u_shape_clipper.dart';

class StoreContentWidget extends StatefulWidget {
  final AppContent content;
  final Function(ContentStore store)? onStoreTap;
  final VoidCallback? onViewAllTap;

  const StoreContentWidget({
    super.key,
    required this.content,
    this.onStoreTap,
    this.onViewAllTap,
  });

  @override
  State<StoreContentWidget> createState() => _StoreContentWidgetState();
}

class _StoreContentWidgetState extends State<StoreContentWidget> {
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
  void didUpdateWidget(StoreContentWidget oldWidget) {
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
    final stores = widget.content.stores ?? [];
    if (stores.isEmpty) return const SizedBox.shrink();

    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.content.showTitle && widget.content.title != null) ...[
          Text(
            widget.content.title!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
        if (widget.content.showSubtitle && widget.content.subtitle != null) ...[
          Text(
            widget.content.subtitle!,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ] else if (widget.content.showTitle && widget.content.title != null) ...[
          const SizedBox(height: 8),
        ],
        _buildStoreList(stores),
      ],
    );

    // Apply background if enabled
    if (widget.content.background?.enabled == true) {
      // Background logic same as ProductWidget
      if (widget.content.background?.type == BackgroundType.video &&
          _videoController != null &&
          _isVideoInitialized) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Stack(
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
          ),
        );
      }
      
      contentWidget = Container(
        decoration: _buildBackgroundDecoration(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10), // Minimal bottom padding
        child: contentWidget,
      );
    } else {
      contentWidget = Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), // Minimal bottom padding
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
      default:
        return const BoxDecoration();
    }
  }

  Widget _buildStoreList(List<ContentStore> stores) {
    switch (widget.content.style) {
      case ContentStyle.style1:
        return _buildStyle1(stores);
      case ContentStyle.style2:
        return _buildStyle2(stores);
      case ContentStyle.style3:
        return _buildStyle3(stores);
      case ContentStyle.style4:
        return _buildStyle4(stores);
    }
  }

  // Style 1: Simple Grid (configurable columns)
  // Style 1: "Inverted U" Card with Explore Button (Custom Painter)
  Widget _buildStyle1(List<ContentStore> stores) {
    int columns = widget.content.gridColumns ?? 3;
    
    // Dynamic sizing based on store count
    if (stores.length == 2) {
      columns = 2; // If only 2 stores, make them larger (2 per row) to fill the space
    } else {
      if (columns < 2) columns = 3; // Safety check for other cases
    }
    // Dynamic sizing variables
    final bool isLarge = columns == 2;
    // Drastically increase sizes for 2-column mode to "cover full white card"
    final double logoSize = isLarge ? 100 : 60; 
    final double nameFontSize = isLarge ? 15 : 12;
    final double buttonFontSize = isLarge ? 13 : 11;
    final double topPadding = isLarge ? 24 : 20;
    final double buttonVerticalPadding = isLarge ? 10 : 6;
    // Reverted aspect ratios to fix "card height" issue (it was actually padding below)
    final double aspectRatio = isLarge ? 0.75 : 0.65; 

    return GridView.builder(
      padding: EdgeInsets.zero, // Emsure no internal padding
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return GestureDetector(
          onTap: () => widget.onStoreTap?.call(store),
          child: CustomPaint(
            painter: UShapeShadowPainter(), // Draw shadow
            child: ClipPath(
              clipper: UShapeClipper(), // Clip content to U shape
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end, // Push content to bottom
                  children: [
                    // Top Section: Image and Name
                    Padding(
                      padding: EdgeInsets.only(top: topPadding, left: 4, right: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Round Store Logo
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            child: ClipOval(child: _buildImage(store.logo)),
                          ),
                          const SizedBox(height: 8), // Slightly more space for larger items
                          // Store Name
                          Text(
                            store.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: nameFontSize,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),

                    // Bottom Button: Explore
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 16), // Wider horizontal padding for huge button
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A250),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Explore',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // Style 2: Shop by Store (Vertical Grid: 2 per row, unlimited rows)
  Widget _buildStyle2(List<ContentStore> stores) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Changed to 2 for wider cards
        mainAxisSpacing: 12, // Slightly more spacing
        crossAxisSpacing: 12,
        childAspectRatio: 0.72, // Taller aspect ratio for "nice" portrait look
      ),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        
        return GestureDetector(
          onTap: () => widget.onStoreTap?.call(store),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image using _buildImage for proper URL handling & error fallback
                  _buildImage(store.coverImage ?? store.logo),

                  // Top gradient shadow for text readability
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Store Name (Top Left, White Text)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  
                  // Rating Badge (Bottom Right)
                  if (store.rating != null)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            )
                          ]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              store.rating.toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, size: 10, color: Color(0xFF0F8C3B)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Style 3: Horizontal Medium Cards (Pizza Hut Style)
  Widget _buildStyle3(List<ContentStore> stores) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        addAutomaticKeepAlives: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          final hasDiscount = store.discountText != null && store.discountText!.isNotEmpty; 
          final isAd = true; // Always show 'Ad' badge for Style 3 as requested

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => widget.onStoreTap?.call(store),
              child: Container(
                width: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main Card Body (Column)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Half: Image and Internal Badges
                        SizedBox(
                          height: 150,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Stack(
                              children: [
                                // Image
                                Positioned.fill(
                                   child: _buildImage(store.coverImage ?? store.logo),
                                ),
                                
                                // Discount Badge (Top Left)
                                if (hasDiscount)
                                  Positioned(
                                    top: 16,
                                    left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
                                      ),
                                      child: Text(
                                        store.discountText!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Ad Badge (Bottom Right)
                                if (isAd)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Ad',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Bottom Half: Content
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                            ),
                            padding: const EdgeInsets.fromLTRB(14, 20, 14, 12), // Top padding to clear badge
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  store.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, size: 16, color: Color(0xFF0F8C3B)),
                                    // Delivery Time
                                    if (store.deliveryTime != null && store.deliveryTime!.isNotEmpty)
                                      Text(
                                        store.deliveryTime!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F8C3B),
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

                    // Overlapping Rating Badge (Floating)
                    if (store.rating != null)
                      Positioned(
                        top: 136, // 150 (Image Height) - 14 (Approx Half Badge Height)
                        left: 2, // Moved slightly left from 14
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(3), // White border effect
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F8C3B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  store.rating.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.star, size: 10, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Style 4: Large Vertical Cards (Feed Style)
  Widget _buildStyle4(List<ContentStore> stores) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        // Dynamic color/icon logic
        final isFast = (store.deliveryTime ?? '').contains('20') || (store.deliveryTime ?? '').contains('25');
        final themeColor = isFast ? const Color(0xFF0F8C3B) : Colors.black54;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
          child: GestureDetector(
            onTap: () => widget.onStoreTap?.call(store),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: SizedBox(
                          height: 170,
                          width: double.infinity,
                          child: _buildImage(store.coverImage ?? store.logo),
                        ),
                      ),
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3), // Top gradient for bookmark
                                Colors.transparent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Promo Badge (Top Left)
                      if (store.isPromoted)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Promoted', 
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                      // Bookmark Icon (Top Right)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Icon(
                          Icons.bookmark_border_rounded,
                          color: Colors.white.withValues(alpha: 0.95),
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Rating Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                store.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (store.rating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F8C3B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      store.rating.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),

                        // Delivery Info
                        if (store.deliveryTime != null && store.deliveryTime!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                isFast ? Icons.bolt : Icons.access_time_filled, 
                                size: 18, 
                                color: themeColor
                              ),
                              const SizedBox(width: 4),
                              Text(
                                store.deliveryTime!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),

                        // Offer / Promo Row (Bottom)
                        if (store.discountText != null && store.discountText!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.verified, size: 18, color: Colors.blue),
                              const SizedBox(width: 6),
                              Text(
                                store.discountText!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return SvgPicture.asset(
        'assets/icons/placeholder.svg',
        fit: BoxFit.cover,
      );
    }
    final fullUrl = imageUrl.startsWith('http') ? imageUrl : AppConstants.getFullMediaUrl(imageUrl);
    return CachedImage(
      imageUrl: fullUrl,
      fit: BoxFit.cover,
      errorWidget: SvgPicture.asset(
        'assets/icons/placeholder.svg',
        fit: BoxFit.cover,
      ),
    );
  }
}
