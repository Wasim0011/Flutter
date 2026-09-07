import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../services/video_cache_service.dart';
import '../cached_image.dart';
import 'full_width_media_card.dart';

/// Padded Media Card - Style 2 (With horizontal padding)
/// Supports: single media, multi-grid, auto-slider, videos, backgrounds
class PaddedMediaCard extends StatefulWidget {
  // Single media mode
  final String? imageUrl;
  final String? videoUrl;
  final String? mediaType;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  
  // Multi-item mode
  final List<MediaCardItem>? items;
  final int? gridColumns;
  final int? gridRows;
  final bool enableAutoSlider;
  
  // Background
  final MediaCardBackground? background;
  
  const PaddedMediaCard({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.mediaType = 'image',
    this.height,
    this.width,
    this.onTap,
    this.items,
    this.gridColumns,
    this.gridRows,
    this.enableAutoSlider = false,
    this.background,
  });

  @override
  State<PaddedMediaCard> createState() => _PaddedMediaCardState();
}

class _PaddedMediaCardState extends State<PaddedMediaCard> {
  VideoController? _videoController;
  VideoController? _backgroundVideoController;
  String? _currentVideoUrl;
  String? _currentBackgroundVideoUrl;
  PageController? _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isVideoInitialized = false;
  bool _isBackgroundVideoInitialized = false;
  final bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMedia();
        _initializeBackgroundVideo();
      }
    });
    _initializeAutoSlider();
  }

  @override
  void didUpdateWidget(PaddedMediaCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasAutoSliderState = oldWidget.enableAutoSlider && oldWidget.items != null && oldWidget.items!.length >= 2;
    final isAutoSliderState = widget.enableAutoSlider && widget.items != null && widget.items!.length >= 2;

    if (!wasAutoSliderState && isAutoSliderState) {
      _initializeAutoSlider();
    } else if (wasAutoSliderState && !isAutoSliderState) {
      _pageController?.dispose();
      _pageController = null;
      _autoSlideTimer?.cancel();
      _autoSlideTimer = null;
    } else if (isAutoSliderState && oldWidget.items?.length != widget.items?.length) {
      if (_currentPage >= widget.items!.length) {
        _currentPage = 0;
        if (_pageController?.hasClients == true) {
          _pageController?.jumpToPage(0);
        }
      }
    }

    if (oldWidget.videoUrl != widget.videoUrl || oldWidget.mediaType != widget.mediaType) {
      _disposeVideo();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializeMedia();
      });
    }

    if (oldWidget.background?.mediaUrl != widget.background?.mediaUrl || oldWidget.background?.type != widget.background?.type) {
      _disposeBackgroundVideo();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializeBackgroundVideo();
      });
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _disposeBackgroundVideo();
    _pageController?.dispose();
    _autoSlideTimer?.cancel();
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

  void _disposeBackgroundVideo() {
    if (_currentBackgroundVideoUrl != null) {
      VideoCacheService().releaseController(_currentBackgroundVideoUrl!);
      _backgroundVideoController = null;
      _currentBackgroundVideoUrl = null;
      _isBackgroundVideoInitialized = false;
    }
  }

  void _initializeMedia() {
    if (widget.mediaType == 'video' && widget.videoUrl != null) {
      _initializeVideo(widget.videoUrl!);
    }
  }

  void _initializeAutoSlider() {
    if (widget.enableAutoSlider && 
        widget.items != null && 
        widget.items!.length >= 2) {
      _pageController = PageController();
      _startAutoSlide();
    }
  }

  void _initializeBackgroundVideo() {
    if (widget.background?.type == MediaBackgroundType.video &&
        widget.background?.mediaUrl != null) {
      _initializeBackgroundVideoController(widget.background!.mediaUrl!);
    }
  }

  Future<void> _initializeVideo(String url) async {
    final fullUrl = _getFullUrl(url);
    _currentVideoUrl = fullUrl;

    final entry = VideoCacheService().createController(fullUrl);
    if (entry == null) return;

    setState(() => _videoController = entry.controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentVideoUrl != fullUrl) return;
      setState(() => _isVideoInitialized = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentVideoUrl == fullUrl) VideoCacheService().resumeController(fullUrl);
      });
    });
  }

  Future<void> _initializeBackgroundVideoController(String url) async {
    final fullUrl = _getFullUrl(url);
    _currentBackgroundVideoUrl = fullUrl;

    final entry = VideoCacheService().createController(fullUrl, priority: 0);
    if (entry == null) return;

    setState(() => _backgroundVideoController = entry.controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentBackgroundVideoUrl != fullUrl) return;
      setState(() => _isBackgroundVideoInitialized = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentBackgroundVideoUrl == fullUrl) VideoCacheService().resumeController(fullUrl);
      });
    });
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController != null && widget.items != null) {
        _currentPage = (_currentPage + 1) % widget.items!.length;
        if (_pageController!.hasClients) {
          _pageController!.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return AppConstants.getFullMediaUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    // Multi-item mode
    if (widget.items != null && widget.items!.isNotEmpty) {
      if (widget.enableAutoSlider && widget.items!.length >= 2) {
        content = _buildAutoSlider();
      } else {
        content = _buildGrid();
      }
    }
    // Single media mode
    else {
      content = _buildSingleMedia();
    }

    // Apply background if provided
    if (widget.background != null) {
      content = _buildWithBackground(content);
    } else {
      // Add padding when no background
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: content,
      );
    }

    return content;
  }

  Widget _buildSingleMedia() {
    final height = widget.height ?? 200.0;
    
    Widget mediaWidget;
    if (widget.mediaType == 'video' && widget.videoUrl != null) {
      mediaWidget = _buildVideo(height);
    } else if (widget.imageUrl != null) {
      mediaWidget = _buildImage(widget.imageUrl!, height);
    } else {
      return const SizedBox.shrink();
    }

    if (widget.width != null) {
      mediaWidget = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.width!),
          child: mediaWidget,
        ),
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: mediaWidget);
    }

    return mediaWidget;
  }

  Widget _buildAutoSlider() {
    final height = widget.height ?? 200.0;
    
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items!.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final item = widget.items![index];
          return _buildMediaItem(item);
        },
      ),
    );
  }

  Widget _buildGrid() {
    final columns = widget.gridColumns ?? 1;
    final rows = widget.gridRows ?? 1;
    final cardHeight = widget.height ?? 200.0;
    const spacing = 8.0;
    
    List<Widget> rowWidgets = [];
    for (int rowIndex = 0; rowIndex < rows; rowIndex++) {
      List<Widget> rowCards = [];
      
      for (int colIndex = 0; colIndex < columns; colIndex++) {
        final itemIndex = rowIndex * columns + colIndex;
        if (widget.items != null && itemIndex < widget.items!.length) {
          rowCards.add(
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildMediaItem(widget.items![itemIndex]),
              ),
            ),
          );
        } else {
          rowCards.add(const Expanded(child: SizedBox.shrink()));
        }

        if (colIndex < columns - 1) {
          rowCards.add(const SizedBox(width: spacing));
        }
      }
      
      if (rowCards.isNotEmpty) {
        rowWidgets.add(Row(children: rowCards));
        
        if (rowIndex < rows - 1 && (rowIndex + 1) * columns < (widget.items?.length ?? 0)) {
          rowWidgets.add(const SizedBox(height: spacing));
        }
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rowWidgets,
    );
  }

  Widget _buildMediaItem(MediaCardItem item) {
    Widget mediaWidget;
    
    if (item.type == 'video' && item.videoUrl != null) {
      mediaWidget = _buildItemVideo(item.videoUrl!);
    } else if (item.imageUrl != null) {
      mediaWidget = _buildItemImage(item.imageUrl!);
    } else {
      return const SizedBox.shrink();
    }

    if (item.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: item.onTap, child: mediaWidget),
      );
    }

    return mediaWidget;
  }

  Widget _buildWithBackground(Widget content) {
    if (widget.background!.type == MediaBackgroundType.video) {
      if (_backgroundVideoController != null && _isBackgroundVideoInitialized) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Video(
                    controller: _backgroundVideoController!,
                    controls: NoVideoControls,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ],
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: _buildBackgroundDecoration(),
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    if (widget.background == null) return const BoxDecoration();

    switch (widget.background!.type) {
      case MediaBackgroundType.color:
        return BoxDecoration(
          color: widget.background!.color,
          borderRadius: BorderRadius.circular(8),
        );
      case MediaBackgroundType.image:
      case MediaBackgroundType.gif:
        if (widget.background!.mediaUrl != null) {
          return BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                _getFullUrl(widget.background!.mediaUrl!),
                maxWidth: 800,
                maxHeight: 800,
              ),
              fit: BoxFit.cover,
            ),
          );
        }
        return BoxDecoration(borderRadius: BorderRadius.circular(8));
      default:
        return BoxDecoration(borderRadius: BorderRadius.circular(8));
    }
  }

  Widget _buildImage(String url, double height) {
    final fullUrl = _getFullUrl(url);
    
    return CachedImage(
      imageUrl: fullUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildItemImage(String url) {
    final fullUrl = _getFullUrl(url);
    
    return CachedImage(
      imageUrl: fullUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildVideo(double height) {
    if (_hasError) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          color: AppColors.surfaceLight,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Video(
          controller: _videoController!,
          controls: NoVideoControls,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildItemVideo(String url) {
    return _CachedItemVideo(url: _getFullUrl(url));
  }
}

class _CachedItemVideo extends StatefulWidget {
  final String url;
  const _CachedItemVideo({required this.url});

  @override
  State<_CachedItemVideo> createState() => _CachedItemVideoState();
}

class _CachedItemVideoState extends State<_CachedItemVideo> {
  VideoController? _controller;
  String? _currentUrl;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initVideo();
    });
  }

  @override
  void didUpdateWidget(_CachedItemVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeVideo();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initVideo();
      });
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    if (_currentUrl != null) {
      VideoCacheService().releaseController(_currentUrl!);
      _controller = null;
      _currentUrl = null;
      _isInitialized = false;
    }
  }

  void _initVideo() {
    final url = widget.url;
    _currentUrl = url;

    final entry = VideoCacheService().createController(url);
    if (entry == null) return;

    setState(() => _controller = entry.controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentUrl != url) return;
      setState(() => _isInitialized = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentUrl == url) VideoCacheService().resumeController(url);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Video(
          controller: _controller!,
          controls: NoVideoControls,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
