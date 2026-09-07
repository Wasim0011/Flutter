import '../cached_image.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Banner Brand Card - Optimized for Style 3 (Full-width banners)
/// Full-width banner style with centered brand logo
class BannerBrandCard extends StatelessWidget {
  final int brandId;
  final String name;
  final String? logoUrl;
  final VoidCallback? onTap;

  const BannerBrandCard({
    super.key,
    required this.brandId,
    required this.name,
    this.logoUrl,
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildLogo(),
      ),
    );
  }

  Widget _buildLogo() {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business,
            color: Colors.grey[400],
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return CachedImage(
      imageUrl: _getFullUrl(logoUrl!),
      fit: BoxFit.contain,
      errorWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business,
            color: Colors.grey[400],
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
