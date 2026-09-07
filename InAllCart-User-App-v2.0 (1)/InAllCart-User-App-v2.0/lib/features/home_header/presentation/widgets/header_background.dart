import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/services/video_cache_service.dart';
import '../../domain/entities/home_header_config.dart';

class HeaderBackground extends StatefulWidget {
  final HomeHeaderBackground background;
  final bool extendBelowCards;

  /// When `true`, header is collapsed — pause to free decoder for content videos.
  final ValueNotifier<bool>? isCollapsed;

  const HeaderBackground({
    super.key,
    required this.background,
    this.extendBelowCards = true,
    this.isCollapsed,
  });

  @override
  State<HeaderBackground> createState() => _HeaderBackgroundState();
}

class _HeaderBackgroundState extends State<HeaderBackground> {
  final _videoCache = VideoCacheService();

  VideoController? _videoController;
  bool _hasVideoError = false;
  bool _firstFrameReady = false;
  String? _currentUrl;

  // GlobalKey keeps the Video widget identity stable across rebuilds.
  // Without this, Flutter may unmount+remount Video when the parent rebuilds,
  // causing media_kit to allocate a second ImageReader surface → overflow.
  final _videoKey = GlobalKey();

  StreamSubscription<dynamic>? _paramsSub;

  @override
  void initState() {
    super.initState();
    widget.isCollapsed?.addListener(_onCollapseChanged);
    if (widget.background.type == BackgroundType.video) {
      _startVideo();
    }
  }

  @override
  void didUpdateWidget(HeaderBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      oldWidget.isCollapsed?.removeListener(_onCollapseChanged);
      widget.isCollapsed?.addListener(_onCollapseChanged);
    }
    if (oldWidget.background.url != widget.background.url) {
      _stopListening();
      _firstFrameReady = false;
      _hasVideoError = false;
      if (widget.background.type == BackgroundType.video) {
        _startVideo();
      } else {
        if (_currentUrl != null) {
          _videoCache.releaseController(_currentUrl!);
          _currentUrl = null;
          _videoController = null;
        }
      }
    }
  }

  void _onCollapseChanged() {
    if (_currentUrl == null) return;
    if (widget.isCollapsed?.value == true) {
      _videoCache.pauseController(_currentUrl!);
    } else {
      _videoCache.resumeController(_currentUrl!);
    }
  }

  void _startVideo() {
    final url = widget.background.url;
    if (url == null) return;
    _currentUrl = url;

    final entry = _videoCache.createController(url, priority: 2);
    if (entry == null) {
      if (mounted) setState(() => _hasVideoError = true);
      return;
    }

    _videoController = entry.controller;

    // Always use videoParams stream for first-frame detection.
    //
    // Why not controller.rect?
    //   rect fires when the VideoController allocates its Surface/texture —
    //   this happens BEFORE libmpv has decoded and painted the first frame.
    //   Using rect causes the shimmer to disappear while the surface is still
    //   black, producing the shimmer → black → video flash.
    //
    // videoParams fires when the decoder has actual frame dimensions, meaning
    // a real frame is about to be (or has just been) rendered. The 80ms delay
    // gives the Flutter texture compositor time to present that frame before
    // we hide the shimmer.
    _attachFrameReadyListener(entry.player);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentUrl != url) return;
      if (widget.isCollapsed?.value != true) {
        _videoCache.resumeController(url);
      }
    });
  }

  void _attachFrameReadyListener(Player player) {
    _stopListening();

    _paramsSub = player.stream.videoParams.listen((params) {
      if ((params.w ?? 0) > 0 && mounted && !_firstFrameReady) {
        // 80ms: enough for the texture to composite the first decoded frame
        // without being perceptible as a delay to the user.
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          if (mounted && !_firstFrameReady) {
            setState(() => _firstFrameReady = true);
          }
        });
        _paramsSub?.cancel();
        _paramsSub = null;
      }
    });
  }

  void _stopListening() {
    _paramsSub?.cancel();
    _paramsSub = null;
  }

  @override
  void dispose() {
    _stopListening();
    widget.isCollapsed?.removeListener(_onCollapseChanged);
    if (_currentUrl != null) {
      _videoCache.releaseController(_currentUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.background.hasMedia) return const SizedBox.shrink();
    return ClipRect(child: RepaintBoundary(child: _buildMedia()));
  }

  Widget _buildMedia() {
    switch (widget.background.type) {
      case BackgroundType.video:
        return _buildVideo();
      case BackgroundType.gif:
      case BackgroundType.image:
        return _buildImage();
    }
  }

  Widget _buildVideo() {
    if (_hasVideoError) return _buildErrorPlaceholder();
    if (_videoController == null) return _buildShimmer();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video is always in the tree — never conditionally removed.
        // Removing/re-adding causes Android to allocate a second ImageReader
        // surface on the same player → buffer overflow.
        Video(
          key: _videoKey,
          controller: _videoController!,
          controls: NoVideoControls,
          fit: BoxFit.cover,
        ),
        // Shimmer sits on top and fades out only after the first real
        // decoded frame is ready (videoParams fired + 80ms compositor delay).
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _firstFrameReady ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: _buildShimmer(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.error_outline, color: Colors.grey[500], size: 48),
      ),
    );
  }

  Widget _buildImage() {
    return CachedImage(
      imageUrl: widget.background.url!,
      fit: BoxFit.cover,
      errorWidget: Container(
        color: Colors.grey[200],
        child: Icon(Icons.broken_image, color: Colors.grey[400]),
      ),
    );
  }
}
