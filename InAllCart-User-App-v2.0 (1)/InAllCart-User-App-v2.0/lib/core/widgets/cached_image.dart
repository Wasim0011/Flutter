import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_constants.dart';

/// Cached network image widget with loading and error states
/// Uses cached_network_image package for automatic image caching
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? placeholderColor;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final String? heroTag;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.heroTag,
  });

  /// Factory for avatar images
  factory CachedImage.avatar({
    required String? imageUrl,
    double radius = 20,
    String? heroTag,
  }) {
    return CachedImage(
      imageUrl: imageUrl,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(radius),
      heroTag: heroTag,
      errorWidget: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          'assets/icons/placeholder.svg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Factory for product images
  factory CachedImage.product({
    required String? imageUrl,
    double? width,
    double? height,
    double borderRadius = 8,
    String? heroTag,
    BoxFit fit = BoxFit.cover,
  }) {
    return CachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(borderRadius),
      heroTag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String resolvedUrl = AppConstants.getFullMediaUrl(imageUrl);

    if (resolvedUrl.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(
          'assets/icons/placeholder.svg',
          fit: BoxFit.cover,
        ),
      );
    }

    // Calculate optimal cache dimensions
    final cacheWidth = width != null && width! > 0 && width!.isFinite
        ? (width! * 2).toInt()  // 2x for high DPI screens
        : null;
    final cacheHeight = height != null && height! > 0 && height!.isFinite
        ? (height! * 2).toInt()
        : null;

    Widget image = CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth ?? 800,
      maxHeightDiskCache: cacheHeight ?? 800,
      filterQuality: FilterQuality.medium,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) {
        // Sub-task 6 diagnostics: if an image still fails to load after the
        // getFullMediaUrl() fix, this prints the exact raw path from the API
        // and the fully-resolved URL that failed, so the real cause (if any
        // remains) can be pinpointed from a debug console instead of
        // guessing further. Safe to leave in - debugPrint is a no-op in
        // release builds' console output is simply not visible to end users.
        if (kDebugMode) {
          debugPrint('[CachedImage] failed to load. raw="$imageUrl" resolved="$resolvedUrl" error=$error');
        }
        return _buildErrorWidget();
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    if (heroTag != null) {
      image = Hero(
        tag: heroTag!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        'assets/icons/placeholder.svg',
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Product image with default styling (use CachedImage.product() factory instead)
class CachedProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}

/// Category image with default styling
class CachedCategoryImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isCircular;

  const CachedCategoryImage({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: isCircular
          ? BorderRadius.circular(size / 2)
          : BorderRadius.circular(8),
    );
  }
}

/// Avatar image with default styling (use CachedImage.avatar() factory instead)
class CachedAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? fallbackText;

  const CachedAvatarImage({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context);
    }

    return CachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      errorWidget: _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final text = fallbackText?.isNotEmpty == true
        ? fallbackText![0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

/// Banner image with default styling
class CachedBannerImage extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double borderRadius;

  const CachedBannerImage({
    super.key,
    required this.imageUrl,
    this.height = 150,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}