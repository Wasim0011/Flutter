import '../cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';

/// Checkmark Category Card - Style 4 (Checkmark pattern: 3-4-3-4...)
/// First row: 3 items, Second row: 4 items, repeating pattern
class CheckmarkCategoryCard extends StatelessWidget {
  final int categoryId;
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const CheckmarkCategoryCard({
    super.key,
    required this.categoryId,
    required this.name,
    this.imageUrl,
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
          // Square image card
          Expanded(
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
          const SizedBox(height: 4),
          // Category name below card
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
                    height: 1.2,
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

    return CachedImage(
      imageUrl: _getFullUrl(imageUrl!),
      fit: BoxFit.cover,
      errorWidget: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
    );
  }
}
