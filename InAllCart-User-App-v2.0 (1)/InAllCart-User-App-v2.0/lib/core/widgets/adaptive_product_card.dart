import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cached_image.dart';
import 'variant_selection_bottom_sheet.dart';

import '../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/domain/entities/cart.dart';
import '../../features/products/domain/entities/product.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';

/// Adaptive Product Card with responsive sizing
/// Automatically adjusts based on available width
enum ProductCardSize {
  /// Extra small: 100-120px (4 columns, minimal info)
  xs,
  /// Small: 120-140px (3 columns, compact)
  small,
  /// Medium: 140-180px (2 columns, standard)
  medium,
  /// Large: 180px+ (1-2 columns, full details)
  large,
}

class AdaptiveProductCard extends StatefulWidget {
  final int productId;
  final String name;
  final double price;
  final double? comparePrice;
  final String? imageUrl;
  final String? unit;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlistToggle;
  final bool isInWishlist;
  final bool inStock;
  final Product? product;
  
  /// Optional: Specify card size, otherwise auto-detects from layout
  final ProductCardSize? cardSize;

  const AdaptiveProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    this.comparePrice,
    this.imageUrl,
    this.unit,
    this.rating,
    this.reviewCount,
    this.onTap,
    this.onAddToCart,
    this.onWishlistToggle,
    this.isInWishlist = false,
    this.inStock = true,
    this.product,
    this.cardSize,
  });

  factory AdaptiveProductCard.fromProduct({
    Key? key,
    required Product product,
    ProductCardSize? cardSize,
    VoidCallback? onTap,
    VoidCallback? onAddToCart,
    VoidCallback? onWishlistToggle,
    bool isInWishlist = false,
  }) {
    return AdaptiveProductCard(
      key: key,
      productId: product.id,
      name: product.name,
      price: product.price.amount,
      comparePrice: product.price.comparePrice,
      imageUrl: product.imageUrl,
      unit: product.unit,
      rating: product.rating,
      reviewCount: product.reviewCount,
      inStock: product.inventory.inStock,
      product: product,
      cardSize: cardSize,
      onTap: onTap,
      onAddToCart: onAddToCart,
      onWishlistToggle: onWishlistToggle,
      isInWishlist: isInWishlist,
    );
  }

  @override
  State<AdaptiveProductCard> createState() => _AdaptiveProductCardState();
}

class _AdaptiveProductCardState extends State<AdaptiveProductCard> {
  bool _isLocallyAdding = false;

  // Brand Colors
  final Color _brandGreen = const Color(0xFF0C831F);
  final Color _bgGrey = const Color(0xFFF2F3F5);
  final Color _textBlack = const Color(0xFF1C1C1C);

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return AppConstants.getFullMediaUrl(url);
  }

  CartItem? _findCartItem(Cart cart) {
    try {
      return cart.items.firstWhere((item) => item.productId == widget.productId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) => _isLocallyAdding,
      listener: (context, state) {
        if (_isLocallyAdding && (state is CartLoaded || state is CartError)) {
          setState(() => _isLocallyAdding = false);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = widget.cardSize ?? _detectSize(constraints.maxWidth);
          return _buildCard(context, size);
        },
      ),
    );
  }

  ProductCardSize _detectSize(double width) {
    if (width < 120) return ProductCardSize.xs;
    if (width < 140) return ProductCardSize.small;
    if (width < 180) return ProductCardSize.medium;
    return ProductCardSize.large;
  }

  Widget _buildCard(BuildContext context, ProductCardSize size) {
    final config = _getConfig(size);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(config.borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _bgGrey,
                          borderRadius: BorderRadius.circular(config.borderRadius),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(config.borderRadius),
                          child: _buildImage(),
                        ),
                      ),
                      if (_hasDiscount() && config.showDiscountBadge)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildDiscountBadge(config),
                        ),
                      if (config.showWishlist)
                        Positioned(
                          top: config.badgePadding,
                          right: config.badgePadding,
                          child: _buildWishlistButton(config),
                        ),
                      if (widget.inStock)
                        Positioned(
                          bottom: config.addButtonBottom,
                          right: config.addButtonRight,
                          child: _buildAddButton(context, config),
                        ),
                      if (!widget.inStock)
                        Positioned.fill(child: _buildOutOfStockOverlay(config)),
                    ],
                  ),
                ),
                // Details Section — sizes to content naturally
                Padding(
                  padding: EdgeInsets.all(config.contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.rating != null && widget.rating! > 0 && config.showReviewBadge)
                        ...[
                          _buildReviewBadge(config),
                          SizedBox(height: config.spacing),
                        ],
                      if (config.showDeliveryBadge) ...[
                        _buildDeliveryTime(config),
                        SizedBox(height: config.spacing),
                      ],
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: config.nameFontSize,
                          fontWeight: FontWeight.w600,
                          color: _textBlack,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                        maxLines: config.nameMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.unit != null && config.showUnit)
                        Text(
                          widget.unit!,
                          style: TextStyle(
                            fontSize: config.unitFontSize,
                            color: const Color(0xFF747474),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: config.spacing),
                      _buildPriceRow(config),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  _CardConfig _getConfig(ProductCardSize size) {
    switch (size) {
      case ProductCardSize.xs:
        return _CardConfig(
          imageAspectRatio: 1.0,
          borderRadius: 8,
          contentPadding: 3,
          spacing: 2,
          nameFontSize: 10,
          nameMaxLines: 2,
          unitFontSize: 8,
          priceFontSize: 10,
          addButtonHeight: 22,
          addButtonWidth: 50,
          addButtonFontSize: 9,
          addButtonBottom: -8,
          addButtonRight: 2,
          badgePadding: 4,
          showDiscountBadge: true,
          showWishlist: false, // Hide in xs
          showReviewBadge: false,
          showDeliveryBadge: false,
          showUnit: false,
          discountBadgeFontSize: 8,
          reviewBadgeFontSize: 8,
          deliveryBadgeFontSize: 8,
        );
      case ProductCardSize.small:
        return _CardConfig(
          imageAspectRatio: 1.05,
          borderRadius: 10,
          contentPadding: 4,
          spacing: 2,
          nameFontSize: 11,
          nameMaxLines: 2,
          unitFontSize: 9,
          priceFontSize: 11,
          addButtonHeight: 24,
          addButtonWidth: 55,
          addButtonFontSize: 10,
          addButtonBottom: -9,
          addButtonRight: 2,
          badgePadding: 6,
          showDiscountBadge: true,
          showWishlist: true,
          showReviewBadge: false,
          showDeliveryBadge: false,
          showUnit: true,
          discountBadgeFontSize: 9,
          reviewBadgeFontSize: 9,
          deliveryBadgeFontSize: 9,
        );
      case ProductCardSize.medium:
        return _CardConfig(
          imageAspectRatio: 1.05,
          borderRadius: 12,
          contentPadding: 4,
          spacing: 2,
          nameFontSize: 12.5,
          nameMaxLines: 2,
          unitFontSize: 11,
          priceFontSize: 13,
          addButtonHeight: 28,
          addButtonWidth: 65,
          addButtonFontSize: 12,
          addButtonBottom: -10,
          addButtonRight: 2,
          badgePadding: 8,
          showDiscountBadge: true,
          showWishlist: true,
          showReviewBadge: false,
          showDeliveryBadge: false,
          showUnit: true,
          discountBadgeFontSize: 10,
          reviewBadgeFontSize: 10,
          deliveryBadgeFontSize: 10,
        );
      case ProductCardSize.large:
        return _CardConfig(
          imageAspectRatio: 1.05,
          borderRadius: 12,
          contentPadding: 4,
          spacing: 2,
          nameFontSize: 12.5,
          nameMaxLines: 2,
          unitFontSize: 11,
          priceFontSize: 13,
          addButtonHeight: 28,
          addButtonWidth: 65,
          addButtonFontSize: 12,
          addButtonBottom: -10,
          addButtonRight: 2,
          badgePadding: 8,
          showDiscountBadge: true,
          showWishlist: true,
          showReviewBadge: false,
          showDeliveryBadge: false,
          showUnit: true,
          discountBadgeFontSize: 10,
          reviewBadgeFontSize: 10,
          deliveryBadgeFontSize: 10,
        );
    }
  }

  Widget _buildImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return Container(
        color: _bgGrey,
        child: Center(
          child: Icon(Icons.image_outlined, size: 32, color: Colors.grey[400]),
        ),
      );
    }
    return CachedImage(
      imageUrl: _getFullUrl(widget.imageUrl!),
      fit: BoxFit.cover,
      errorWidget: Icon(Icons.broken_image_outlined, color: Colors.grey[300]),
    );
  }

  bool _hasDiscount() {
    return widget.comparePrice != null && widget.comparePrice! > widget.price;
  }

  Widget _buildDiscountBadge(_CardConfig config) {
    final double discountPercent =
        ((widget.comparePrice! - widget.price) / widget.comparePrice!) * 100;

    return CustomPaint(
      painter: DiscountBadgePainter(color: const Color(0xFFFFE800)),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          config.badgePadding * 0.75,
          config.badgePadding * 0.5,
          config.badgePadding * 1.25,
          config.badgePadding * 0.5,
        ),
        child: Text(
          '${discountPercent.round()}%',
          style: TextStyle(
            fontSize: config.discountBadgeFontSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1C1C1C),
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistButton(_CardConfig config) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      buildWhen: (previous, current) => 
          previous.productIds.contains(widget.productId) != current.productIds.contains(widget.productId),
      builder: (context, state) {
        final isInWishlist = state.productIds.contains(widget.productId);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<WishlistBloc>().add(ToggleWishlistProduct(widget.productId));
            
            // Show feedback
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  !isInWishlist ? 'Added to Wishlist' : 'Removed from Wishlist',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: !isInWishlist ? AppColors.success : Colors.black87,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                width: 200,
              ),
            );
            
            if (widget.onWishlistToggle != null) widget.onWishlistToggle!();
          },
          child: Icon(
            isInWishlist ? Icons.favorite : Icons.favorite_border,
            color: isInWishlist ? Colors.red : const Color(0xFF9ca3af),
            size: config.badgePadding * 2.5,
          ),
        );
      },
    );
  }

  Widget _buildReviewBadge(_CardConfig config) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.badgePadding * 0.75,
        vertical: config.badgePadding * 0.25,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: const Color(0xFF0C831F),
            size: config.reviewBadgeFontSize * 1.2,
          ),
          SizedBox(width: config.spacing),
          Text(
            widget.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: config.reviewBadgeFontSize,
              color: const Color(0xFF1C1C1C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTime(_CardConfig config) {
    return CustomPaint(
      painter: ExpressBadgePainter(color: const Color(0xFFFFE800)),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          config.badgePadding * 1.75,
          config.badgePadding * 0.25,
          config.badgePadding,
          config.badgePadding * 0.375,
        ),
        child: Text(
          '8 min',
          style: TextStyle(
            fontSize: config.deliveryBadgeFontSize,
            color: const Color(0xFF1C1C1C),
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildOutOfStockOverlay(_CardConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(config.borderRadius),
      ),
      child: Center(
        child: Text(
          'Out of Stock',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: config.nameFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(_CardConfig config) {
    final hasDiscount = _hasDiscount();
    double discountPercent = 0;
    if (hasDiscount) {
      discountPercent = ((widget.comparePrice! - widget.price) / widget.comparePrice!) * 100;
    }
    final showYellowBadge = discountPercent > 20;

    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, state) {
        final appConfig = state is AppConfigLoaded ? state.config : null;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Price — never ellipsis, always shown in full
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: config.spacing * 2,
                vertical: 0,
              ),
              decoration: BoxDecoration(
                color: showYellowBadge ? const Color(0xFFFFE800) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                CurrencyFormatter.formatAmount(widget.price, appConfig?.currencyConfig),
                style: TextStyle(
                  color: _textBlack,
                  fontSize: config.priceFontSize,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
              ),
            ),
            if (hasDiscount) ...[
              SizedBox(width: config.spacing * 2),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(bottom: config.spacing * 0.5),
                  child: Text(
                    CurrencyFormatter.formatAmount(widget.comparePrice!, appConfig?.currencyConfig),
                    style: TextStyle(
                      fontSize: config.priceFontSize * 0.77,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context, _CardConfig config) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) {
        final prevItem = _findCartItem(previous.cart);
        final currItem = _findCartItem(current.cart);
        return prevItem?.quantity != currItem?.quantity || 
               (prevItem == null) != (currItem == null);
      },
      builder: (context, state) {
        final cartItem = _findCartItem(state.cart);
        final isInCart = cartItem != null && cartItem.quantity > 0;

        if (isInCart) {
          return _buildQuantityStepper(context, cartItem, config);
        }
        return _buildAddButtonContent(context, config);
      },
    );
  }

  Widget _buildAddButtonContent(BuildContext context, _CardConfig config) {
    return GestureDetector(
      onTap: _isLocallyAdding ? null : () {
        HapticFeedback.lightImpact();
        if (widget.onAddToCart != null) {
          widget.onAddToCart!();
        } else {
          _addToCart(context);
        }
      },
      child: Container(
        height: config.addButtonHeight,
        width: config.addButtonWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _brandGreen, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isLocallyAdding
            ? Center(
                child: SizedBox(
                  width: config.addButtonHeight * 0.43,
                  height: config.addButtonHeight * 0.43,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_brandGreen),
                  ),
                ),
              )
            : Center(
                child: Text(
                  'ADD',
                  style: TextStyle(
                    color: _brandGreen,
                    fontSize: config.addButtonFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartItem cartItem, _CardConfig config) {
    return Container(
      height: config.addButtonHeight,
      decoration: BoxDecoration(
        color: _brandGreen,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepperButton(
            icon: Icons.remove,
            onTap: () {
              HapticFeedback.lightImpact();
              _updateQuantity(context, cartItem, cartItem.quantity - 1);
            },
            height: config.addButtonHeight,
          ),
          Container(
            constraints: BoxConstraints(minWidth: config.addButtonHeight * 0.8),
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: TextStyle(
                color: Colors.white,
                fontSize: config.addButtonFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildStepperButton(
            icon: Icons.add,
            onTap: () {
              HapticFeedback.lightImpact();
              _updateQuantity(context, cartItem, cartItem.quantity + 1);
            },
            height: config.addButtonHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap, required double height}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: height * 0.85,
        height: height,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: height * 0.5),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    VariantSelectionBottomSheet.showForCard(
      context: context,
      productId: widget.productId,
      name: widget.name,
      price: widget.price,
      comparePrice: widget.comparePrice,
      imageUrl: widget.imageUrl,
      unit: widget.unit,
      inStock: widget.inStock,
      product: widget.product,
    );
  }

  void _updateQuantity(BuildContext context, CartItem cartItem, int newQuantity) {
    if (newQuantity <= 0) {
      context.read<CartBloc>().add(RemoveFromCartEvent(cartItem.id));
    } else {
      context.read<CartBloc>().add(
        UpdateCartItemEvent(itemId: cartItem.id, quantity: newQuantity),
      );
    }
  }
}

class _CardConfig {
  final double imageAspectRatio;
  final double borderRadius;
  final double contentPadding;
  final double spacing;
  final double nameFontSize;
  final int nameMaxLines;
  final double unitFontSize;
  final double priceFontSize;
  final double addButtonHeight;
  final double addButtonWidth;
  final double addButtonFontSize;
  final double addButtonBottom;
  final double addButtonRight;
  final double badgePadding;
  final bool showDiscountBadge;
  final bool showWishlist;
  final bool showReviewBadge;
  final bool showDeliveryBadge;
  final bool showUnit;
  final double discountBadgeFontSize;
  final double reviewBadgeFontSize;
  final double deliveryBadgeFontSize;

  _CardConfig({
    required this.imageAspectRatio,
    required this.borderRadius,
    required this.contentPadding,
    required this.spacing,
    required this.nameFontSize,
    required this.nameMaxLines,
    required this.unitFontSize,
    required this.priceFontSize,
    required this.addButtonHeight,
    required this.addButtonWidth,
    required this.addButtonFontSize,
    required this.addButtonBottom,
    required this.addButtonRight,
    required this.badgePadding,
    required this.showDiscountBadge,
    required this.showWishlist,
    required this.showReviewBadge,
    required this.showDeliveryBadge,
    required this.showUnit,
    required this.discountBadgeFontSize,
    required this.reviewBadgeFontSize,
    required this.deliveryBadgeFontSize,
  });
}

// Custom Painters (same as before)
class ExpressBadgePainter extends CustomPainter {
  final Color color;
  ExpressBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final double radius = size.height / 2;
    final double slantOffset = 8.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(slantOffset + 4, size.height);
    path.quadraticBezierTo(slantOffset, size.height, slantOffset - 3, size.height - 3);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiscountBadgePainter extends CustomPainter {
  final Color color;
  DiscountBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    const double radius = 12.0;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, radius);
    path.arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius), clockwise: true);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height), radius: const Radius.circular(radius), clockwise: true);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
