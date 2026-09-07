import '../cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';

/// Grid Category Card - Optimized for Style 2 (Image card with text below)
/// Curved image card with category name displayed below separately
class GridCategoryCard extends StatelessWidget {
  final int categoryId;
  final String name;
  final String? imageUrl;
  final int? productCount;
  final VoidCallback? onTap;

  const GridCategoryCard({
    super.key,
    required this.categoryId,
    required this.name,
    this.imageUrl,
    this.productCount,
    this.onTap,
  });

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return AppConstants.getFullMediaUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // perfectly square image card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0), // Slight reduction to width and height
            child: AspectRatio(
              aspectRatio: 1.0, // Force perfect mathematically square
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Category name below card - takes fixed space
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              height: 30, // Fix height for up to 2 lines of text
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover);
    }

    return LayoutBuilder(
      builder: (context, constraints) => CachedImage(
        imageUrl: _getFullUrl(imageUrl!),
        width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
        height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
        fit: BoxFit.cover,
        errorWidget: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
      ),
    );
  }
}
