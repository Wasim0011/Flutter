import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/domain/entities/cart.dart';

class CartRecommendedSection extends StatefulWidget {
  final List<int> categoryIds; // from cart items

  const CartRecommendedSection({super.key, required this.categoryIds});

  @override
  State<CartRecommendedSection> createState() => _CartRecommendedSectionState();
}

class _CartRecommendedSectionState extends State<CartRecommendedSection> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CartRecommendedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryIds.join() != widget.categoryIds.join()) _load();
  }

  Future<void> _load() async {
    if (widget.categoryIds.isEmpty) {
      setState(() { _loading = false; _products = []; });
      return;
    }
    setState(() => _loading = true);
    // Use first category for recommendations
    final useCase = getIt<GetProducts>();
    final result = await useCase(categoryId: widget.categoryIds.first, perPage: 10);
    result.fold(
      (_) => setState(() { _loading = false; _products = []; }),
      (products) => setState(() { _loading = false; _products = products; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_products.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Text(
                  'You might also like',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push(
                    Routes.products,
                    extra: {'categoryId': widget.categoryIds.first},
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              itemCount: _products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _RecommendedProductCard(product: _products[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedProductCard extends StatelessWidget {
  final Product product;
  const _RecommendedProductCard({required this.product});

  CartItem? _findCartItem(Cart cart) {
    try {
      return cart.items.firstWhere((i) => i.productId == product.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl.isNotEmpty
        ? AppConstants.getFullMediaUrl(product.imageUrl)
        : null;
    final hasDiscount = product.hasDiscount && product.price.comparePrice != null && product.price.comparePrice! > product.price.amount;

    return GestureDetector(
      onTap: () => context.push(Routes.product(product.id.toString()), extra: product),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: imageUrl != null
                    ? CachedImage(imageUrl: imageUrl, width: 130, height: 100, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 28),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price row
                    BlocBuilder<AppConfigBloc, AppConfigState>(
                      builder: (context, state) {
                        final config = state is AppConfigLoaded ? state.config : null;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                CurrencyFormatter.formatAmount(product.price.amount, config?.currencyConfig),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  CurrencyFormatter.formatAmount(product.price.comparePrice!, config?.currencyConfig),
                                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    // Add button
                    BlocBuilder<CartBloc, CartState>(
                      buildWhen: (prev, curr) {
                        final p = prev.cart.items.any((i) => i.productId == product.id);
                        final c = curr.cart.items.any((i) => i.productId == product.id);
                        return p != c || _findCartItem(prev.cart)?.quantity != _findCartItem(curr.cart)?.quantity;
                      },
                      builder: (context, state) {
                        final cartItem = _findCartItem(state.cart);
                        if (cartItem != null) {
                          return _buildStepper(context, cartItem);
                        }
                        return _buildAddButton(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.read<CartBloc>().add(AddToCartEvent(
            productId: product.id,
            quantity: 1,
            productName: product.name,
            productImage: product.imageUrl,
            price: product.price.amount,
          ));
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text('ADD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ),
    );
  }

  Widget _buildStepper(BuildContext context, CartItem cartItem) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (cartItem.quantity > 1) {
                context.read<CartBloc>().add(UpdateCartItemEvent(itemId: cartItem.id, quantity: cartItem.quantity - 1));
              } else {
                context.read<CartBloc>().add(RemoveFromCartEvent(cartItem.id));
              }
            },
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.remove, size: 14, color: Colors.white)),
          ),
          Text('${cartItem.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<CartBloc>().add(UpdateCartItemEvent(itemId: cartItem.id, quantity: cartItem.quantity + 1));
            },
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.add, size: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
