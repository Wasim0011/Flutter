import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/cart/domain/entities/cart.dart';
import '../../../features/products/domain/entities/product.dart';
import '../replace_cart_bottom_sheet.dart';
import '../variant_selection_bottom_sheet.dart';

/// Mixin providing Premium-style cart button functionality for product cards.
/// 
/// This mixin provides:
/// - Local loading state (only this card shows loading, not all cards)
/// - Quantity stepper when item is in cart
/// - Optimized rebuilds (only rebuild when THIS product's cart quantity changes)
mixin CartButtonMixin<T extends StatefulWidget> on State<T> {
  bool isLocallyAdding = false;
  
  final Color brandGreen = const Color(0xFF0C831F);

  /// Optional: Override to provide the Product model if available
  Product? get product => null;
  
  /// Override this to provide the product ID for this card
  int get productId;
  
  /// Override this to provide the product name for snackbar
  String get productName;
  
  /// Override this to provide the product image URL
  String? get productImage;
  
  /// Override this to provide the product price
  double get productPrice;
  
  /// Called when login is required
  void showLoginRequiredDialog(BuildContext context) {}
  
  /// Find cart item for this product
  CartItem? findCartItem(Cart cart) {
    try {
      return cart.items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// Build the cart button (ADD or quantity stepper)
  Widget buildCartButton(BuildContext context, {double height = 28, double width = 65}) {
    return BlocConsumer<CartBloc, CartState>(
      listenWhen: (previous, current) => isLocallyAdding,
      listener: (context, state) {
        if (isLocallyAdding && (state is CartLoaded || state is CartError || state is CartAuthRequired)) {
          setState(() => isLocallyAdding = false);
          if (state is CartError && (state.message.contains('different stores') || state.message.contains('clear your cart'))) {
            _showReplaceCartDialog(context);
          }
        }
      },
      buildWhen: (previous, current) {
        // Rebuild only when cart items change for THIS product
        final prevItem = findCartItem(previous.cart);
        final currItem = findCartItem(current.cart);
        return prevItem?.quantity != currItem?.quantity || 
               (prevItem == null) != (currItem == null);
      },
      builder: (context, state) {
        final cartItem = findCartItem(state.cart);
        final isInCart = cartItem != null && cartItem.quantity > 0;

        if (isInCart) {
          return buildQuantityStepper(context, cartItem, height: height);
        }
        return buildAddButton(context, height: height, width: width);
      },
    );
  }

  Widget buildAddButton(BuildContext context, {double height = 28, double width = 65}) {
    return GestureDetector(
      onTap: isLocallyAdding ? null : () => addToCart(context),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: brandGreen, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLocallyAdding
            ? Center(
                child: SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(brandGreen),
                  ),
                ),
              )
            : Center(
                child: Text(
                  'ADD',
                  style: TextStyle(
                    color: brandGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  Widget buildQuantityStepper(BuildContext context, CartItem cartItem, {double height = 28}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: brandGreen,
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
            onTap: () => updateQuantity(context, cartItem, cartItem.quantity - 1),
            height: height,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
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
            icon: Icons.add,
            onTap: () => updateQuantity(context, cartItem, cartItem.quantity + 1),
            height: height,
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon, 
    required VoidCallback onTap,
    double height = 28,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: height,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  void addToCart(BuildContext context) {
    final p = product;
    if (p != null && p.hasVariants && p.variants.length > 1) {
      VariantSelectionBottomSheet.show(context, p);
      return;
    }
    setState(() => isLocallyAdding = true);
    context.read<CartBloc>().add(
      AddToCartEvent(
        productId: productId,
        quantity: 1,
        productName: productName,
        productImage: productImage,
        price: productPrice,
      ),
    );
  }


  void updateQuantity(BuildContext context, CartItem cartItem, int newQuantity) {
    if (newQuantity <= 0) {
      context.read<CartBloc>().add(RemoveFromCartEvent(cartItem.id));
    } else {
      context.read<CartBloc>().add(
        UpdateCartItemEvent(itemId: cartItem.id, quantity: newQuantity),
      );
    }
  }

  void _showReplaceCartDialog(BuildContext context) {
    showReplaceCartBottomSheet(
      context,
      onConfirm: () {
        context.read<CartBloc>().add(ClearCartEvent());
        Future.delayed(const Duration(milliseconds: 200), () {
          if (context.mounted) {
            addToCart(context);
          }
        });
      },
    );
  }
}
