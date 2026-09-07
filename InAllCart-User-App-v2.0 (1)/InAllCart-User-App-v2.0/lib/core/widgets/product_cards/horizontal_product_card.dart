import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cached_image.dart';
import '../variant_selection_bottom_sheet.dart';
import '../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/cart/domain/entities/cart.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../../features/wishlist/presentation/bloc/wishlist_bloc.dart';

/// Horizontal Product Card - Optimized for Style 2 (Horizontal scrolling lists)
/// Fixed width: 150px, perfect for horizontal scrolling
class HorizontalProductCard extends StatefulWidget {
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
  final String? heroTag;
  final Product? product;

  const HorizontalProductCard({
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
    this.heroTag,
    this.product,
  });

  @override
  State<HorizontalProductCard> createState() => _HorizontalProductCardState();
}

class _HorizontalProductCardState extends State<HorizontalProductCard> {
  bool _isLocallyAdding = false;

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _bgGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(),
                        ),
                      ),
                      if (_hasDiscount())
                        Positioned(top: 0, left: 0, child: _buildDiscountBadge()),
                      Positioned(top: 8, right: 8, child: _buildWishlistButton()),
                      if (widget.inStock)
                        Positioned(bottom: -10, right: 2, child: _buildCartButton(context)),
                      if (!widget.inStock)
                        Positioned.fill(child: _buildOutOfStockOverlay()),
                    ],
                  ),
                ),
                // Details section — sizes to content
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.rating != null && widget.rating! > 0) ...[
                        _buildReviewBadge(),
                        const SizedBox(height: 3),
                      ],
                      _buildDeliveryTime(),
                      const SizedBox(height: 4),
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textBlack,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.unit != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.unit!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF747474),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildPriceRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.grey[300]),
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

  Widget _buildDiscountBadge() {
    final double discountPercent =
        ((widget.comparePrice! - widget.price) / widget.comparePrice!) * 100;

    return CustomPaint(
      painter: DiscountBadgePainter(color: const Color(0xFFFFE800)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 3, 8, 3),
        child: Text(
          '${discountPercent.round()}%',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C1C1C),
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
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
            size: 18,
          ),
        );
      },
    );
  }

  Widget _buildReviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFF0C831F), size: 10),
          const SizedBox(width: 2),
          Text(
            widget.rating!.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF1C1C1C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTime() {
    return CustomPaint(
      painter: ExpressBadgePainter(color: const Color(0xFFFFE800)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
        child: const Text(
          '8 min',
          style: TextStyle(
            fontSize: 9,
            color: Color(0xFF1C1C1C),
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildOutOfStockOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Out of Stock',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    final hasDiscount = _hasDiscount();
    double discountPercent = 0;
    if (hasDiscount) {
      discountPercent = ((widget.comparePrice! - widget.price) / widget.comparePrice!) * 100;
    }
    final showYellowBadge = discountPercent > 20;

    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, state) {
        final config = state is AppConfigLoaded ? state.config : null;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
              decoration: BoxDecoration(
                color: showYellowBadge ? const Color(0xFFFFE800) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                CurrencyFormatter.formatAmount(widget.price, config?.currencyConfig),
                style: TextStyle(
                  color: _textBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    CurrencyFormatter.formatAmount(widget.comparePrice!, config?.currencyConfig),
                    style: const TextStyle(
                      fontSize: 9,
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

  Widget _buildCartButton(BuildContext context) {
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
          return _buildQuantityStepper(context, cartItem);
        }
        return _buildAddButton(context);
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
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
        height: 26,
        width: 60,
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
                  width: 11,
                  height: 11,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartItem cartItem) {
    return Container(
      height: 26,
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
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 20,
        height: 26,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 13),
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


class ExpressBadgePainter extends CustomPainter {
  final Color color;
  ExpressBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final double radius = size.height / 2;
    final double slantOffset = 7.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(slantOffset + 3, size.height);
    path.quadraticBezierTo(slantOffset, size.height, slantOffset - 2, size.height - 2);
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
    const double radius = 10.0;
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
