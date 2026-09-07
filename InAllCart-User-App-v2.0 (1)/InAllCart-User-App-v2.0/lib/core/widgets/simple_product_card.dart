import './cached_image.dart';
import './variant_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/domain/entities/cart.dart';
import '../../features/products/domain/entities/product.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter/services.dart';

/// Simple Product Card Widget for Content Widgets
/// Matches the exact design from GlobalProductCard with:
/// - Product image with wishlist icon (top-right)
/// - Discount badge (top-left, yellow with custom shape)
/// - Review badge (if available)
/// - Express delivery badge (8 minutes)
/// - Product name
/// - Unit/weight below name
/// - Price with yellow highlight for >20% discount
/// - Add button (bottom-right, floating over image)
class SimpleProductCard extends StatefulWidget {
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

  const SimpleProductCard({
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
  });

  @override
  State<SimpleProductCard> createState() => _SimpleProductCardState();
}

class _SimpleProductCardState extends State<SimpleProductCard> 
    with SingleTickerProviderStateMixin {
  bool _isLocallyAdding = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Exact Brand Colors
  final Color _brandGreen = const Color(0xFF0C831F);
  final Color _bgGrey = const Color(0xFFF2F3F5);
  final Color _textBlack = const Color(0xFF1C1C1C);

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return AppConstants.getFullMediaUrl(url);
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
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
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. IMAGE SECTION (Dynamic Ratio)
                AspectRatio(
                  aspectRatio: 1.05,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Grey Background Container
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _bgGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(),
                        ),
                      ),

                      // --- DISCOUNT BADGE (Top Left) ---
                      if (_hasDiscount())
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildDiscountBadge(),
                        ),

                      // Wishlist Heart (Top Right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildWishlistButton(),
                      ),

                      // ADD Button (Floating)
                      if (widget.inStock)
                        Positioned(
                          bottom: -10,
                          right: 2,
                          child: _buildCartButton(context),
                        ),

                      // Out of Stock Overlay
                      if (!widget.inStock)
                        Positioned.fill(child: _buildOutOfStockOverlay()),
                    ],
                  ),
                ),

                // 2. DETAILS SECTION
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- REVIEW BADGE ---
                        if (widget.rating != null && widget.rating! > 0)
                          _buildReviewBadge(),
                        
                        if (widget.rating != null && widget.rating! > 0)
                          const SizedBox(height: 2),
                        
                        // --- EXPRESS BADGE ---
                        _buildDeliveryTime(),
                        
                        const SizedBox(height: 6),

                        // Product Name
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _textBlack,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),

                        // Weight / Unit
                        if (widget.unit != null)
                          Text(
                            widget.unit!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF747474),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        const Spacer(),

                        // Price Section
                        _buildPriceRow(),
                      ],
                    ),
                  ),
                ),
              ],
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
    return LayoutBuilder(
      builder: (context, constraints) => CachedImage(
        imageUrl: _getFullUrl(widget.imageUrl!),
        width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
        height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
        fit: BoxFit.cover,
        errorWidget: Icon(Icons.broken_image_outlined, color: Colors.grey[300]),
      ),
    );
  }

  // --- DISCOUNT BADGE WIDGET ---
  bool _hasDiscount() {
    return widget.comparePrice != null && widget.comparePrice! > widget.price;
  }

  Widget _buildDiscountBadge() {
    final double discountPercent = 
        ((widget.comparePrice! - widget.price) / widget.comparePrice!) * 100;

    return CustomPaint(
      painter: DiscountBadgePainter(color: const Color(0xFFFFE800)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        child: Text(
          '${discountPercent.round()}% OFF',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C1C1C),
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onWishlistToggle != null) widget.onWishlistToggle!();
      },
      child: Container(
        color: Colors.transparent,
        child: Icon(
          widget.isInWishlist ? Icons.favorite : Icons.favorite_border,
          color: widget.isInWishlist ? Colors.red : const Color(0xFF9ca3af),
          size: 20,
        ),
      ),
    );
  }

  // --- REVIEW BADGE ---
  Widget _buildReviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Color(0xFF0C831F),
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            widget.rating!.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF1C1C1C),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.reviewCount != null && widget.reviewCount! > 0) ...[
            const SizedBox(width: 3),
            Text(
              '(${_formatReviewCount(widget.reviewCount!)})',
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF747474),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // --- DELIVERY TIME BADGE ---
  Widget _buildDeliveryTime() {
    return CustomPaint(
      painter: ExpressBadgePainter(color: const Color(0xFFFFE800)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 2, 8, 3), 
        child: const Text(
          '8 minutes',
          style: TextStyle(
            fontSize: 10,
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
            fontSize: 11
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    final hasDiscount = widget.comparePrice != null && widget.comparePrice! > widget.price;
    
    // Calculate discount percentage
    double discountPercent = 0;
    if (hasDiscount) {
      discountPercent = ((widget.comparePrice! - widget.price) / widget.comparePrice!) * 100;
    }
    
    // Show yellow badge only if discount is over 20%
    final showYellowBadge = discountPercent > 20;

    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, state) {
        final config = state is AppConfigLoaded ? state.config : null;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Price with conditional yellow background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              decoration: BoxDecoration(
                 color: showYellowBadge ? const Color(0xFFFFE800) : Colors.transparent,
                 borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                CurrencyFormatter.formatAmount(widget.price, config?.currencyConfig),
                style: TextStyle(
                  color: _textBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  CurrencyFormatter.formatAmount(widget.comparePrice!, config?.currencyConfig),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Premium-style cart button: Shows ADD -> then shows quantity stepper
  Widget _buildCartButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) {
        // Rebuild only when cart items change for THIS product
        final prevItem = _findCartItem(previous.cart);
        final currItem = _findCartItem(current.cart);
        return prevItem?.quantity != currItem?.quantity || 
               (prevItem == null) != (currItem == null);
      },
      builder: (context, state) {
        final cartItem = _findCartItem(state.cart);
        final isInCart = cartItem != null && cartItem.quantity > 0;

        // Show quantity stepper if in cart
        if (isInCart) {
          return _buildQuantityStepper(context, cartItem);
        }

        // Show ADD button
        return _buildAddButton(context);
      },
    );
  }

  CartItem? _findCartItem(Cart cart) {
    try {
      return cart.items.firstWhere(
        (item) => item.productId == widget.productId,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: _isLocallyAdding ? null : () {
        HapticFeedback.lightImpact();
        _addToCart(context);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 28,
          width: 65,
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
                    width: 12, height: 12,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartItem cartItem) {
    return Container(
      height: 28,
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
          // Minus button
          _buildStepperButton(
            icon: Icons.remove,
            onTap: () {
              HapticFeedback.lightImpact();
              _updateQuantity(context, cartItem, cartItem.quantity - 1);
            },
          ),
          // Quantity display
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Plus button
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
        width: 26,
        height: 28,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 16),
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


/// REVERSED PAINTER: (Used for '8 minutes')
class ExpressBadgePainter extends CustomPainter {
  final Color color;
  
  ExpressBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
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
    path.quadraticBezierTo(
      slantOffset, size.height,
      slantOffset - 3, size.height - 3
    );
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// DISCOUNT BADGE PAINTER (Premium Style)
/// - Top Left: Rounded (12px)
/// - Top Right: Straight (0px)
/// - Bottom Right: Curved (12px)
/// - Bottom Left: Straight (0px)
class DiscountBadgePainter extends CustomPainter {
  final Color color;

  DiscountBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double radius = 12.0; // For top-left and bottom-right curves

    final path = Path();

    // 1. Start at Bottom-Left (Straight corner)
    path.moveTo(0, size.height);

    // 2. Line up to Top-Left curve start
    path.lineTo(0, radius);

    // 3. Top-Left Rounded Corner
    path.arcToPoint(
      const Offset(radius, 0),
      radius: const Radius.circular(radius),
      clockwise: true,
    );

    // 4. Line to Top-Right (Straight corner)
    path.lineTo(size.width, 0);

    // 5. Line down to Bottom-Right curve start (Straight edge)
    path.lineTo(size.width, size.height - radius);

    // 6. Bottom-Right Curved Corner
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
      clockwise: true,
    );

    // 7. Close back to Bottom-Left (Straight edge)
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
