import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cached_image.dart';
import '../variant_selection_bottom_sheet.dart';
import 'package:flutter/services.dart';

import '../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/cart/domain/entities/cart.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';

/// Large Product Card - Optimized for Style 3 (Large single-column cards)
/// Horizontal layout: Image left (120x120), details right, add button right
class LargeProductCard extends StatefulWidget {
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
  final bool inStock;
  final Product? product;

  const LargeProductCard({
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
    this.inStock = true,
    this.product,
    this.heroTag,
  });

  final String? heroTag;

  @override
  State<LargeProductCard> createState() => _LargeProductCardState();
}

class _LargeProductCardState extends State<LargeProductCard> {
  bool _isLocallyAdding = false;

  final Color _brandGreen = const Color(0xFF0C831F);

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
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 120,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: _buildImage(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.rating != null && widget.rating! > 0) ...[
                              _buildReviewBadge(),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              widget.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (widget.unit != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.unit!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            _buildPriceRow(),
                            if (_hasDiscount()) ...[
                              const SizedBox(height: 2),
                              _buildDiscountAmount(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.inStock)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildCartButton(context),
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
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
        ),
      );
    }
    return CachedImage(
      imageUrl: _getFullUrl(widget.imageUrl!),
      width: 120,
      height: 120,
      fit: BoxFit.cover,
      errorWidget: Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey[400]),
        ),
      ),
    );
  }

  bool _hasDiscount() {
    return widget.comparePrice != null && widget.comparePrice! > widget.price;
  }

  Widget _buildReviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFF0C831F), size: 12),
          const SizedBox(width: 3),
          Text(
            widget.rating!.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1C1C1C),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.reviewCount != null && widget.reviewCount! > 0) ...[
            const SizedBox(width: 3),
            Text(
              '(${widget.reviewCount})',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow() {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, state) {
        final config = state is AppConfigLoaded ? state.config : null;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                CurrencyFormatter.formatAmount(widget.price, config?.currencyConfig),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_hasDiscount()) ...[
              const SizedBox(width: 6),
              Text(
                CurrencyFormatter.formatAmount(widget.comparePrice!, config?.currencyConfig),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDiscountAmount() {
    final discountAmount = widget.comparePrice! - widget.price;
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, state) {
        final config = state is AppConfigLoaded ? state.config : null;
        return Text(
          '${CurrencyFormatter.formatAmount(discountAmount, config?.currencyConfig)} OFF',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isLocallyAdding ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isLocallyAdding
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartItem cartItem) {
    return Container(
      decoration: BoxDecoration(
        color: _brandGreen,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepperButton(
            icon: Icons.add,
            onTap: () {
              HapticFeedback.lightImpact();
              _updateQuantity(context, cartItem, cartItem.quantity + 1);
            },
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 24),
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
          _buildStepperButton(
            icon: Icons.remove,
            onTap: () {
              HapticFeedback.lightImpact();
              _updateQuantity(context, cartItem, cartItem.quantity - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
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

