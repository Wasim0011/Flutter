import 'package:flutter/material.dart';

import '../../../../core/widgets/global_product_card.dart';
import '../../domain/entities/product.dart';

/// ProductCard - Now uses GlobalProductCard for consistent design
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlistToggle;
  final bool isInWishlist;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onWishlistToggle,
    this.isInWishlist = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalProductCard(
      product: product,
      onTap: onTap,
      onAddToCart: onAddToCart,
      onWishlistToggle: onWishlistToggle,
      isInWishlist: isInWishlist,
    );
  }
}
