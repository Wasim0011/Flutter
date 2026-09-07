import '../cached_image.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Grid Brand Card - Optimized for Style 2 (Card grid with logos)
/// Grid layout with brand logos in cards
class GridBrandCard extends StatelessWidget {
  final int brandId;
  final String name;
  final String? logoUrl;
  final VoidCallback? onTap;

  const GridBrandCard({
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
      return Center(
        child: Icon(
          Icons.business,
          color: Colors.grey[400],
          size: 48,
        ),
      );
    }

    return CachedImage(
      imageUrl: _getFullUrl(logoUrl!),
      fit: BoxFit.contain,
      errorWidget: Icon(
        Icons.business,
        color: Colors.grey[400],
        size: 48,
      ),
    );
  }
}
