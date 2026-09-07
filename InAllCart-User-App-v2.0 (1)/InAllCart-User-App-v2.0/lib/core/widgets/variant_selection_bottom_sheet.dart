import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/products/domain/entities/product.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'cached_image.dart';

/// Modal Bottom Sheet that pops up when a user taps "ADD" on a product
/// that has multiple variations/attributes available.
class VariantSelectionBottomSheet extends StatefulWidget {
  final Product product;

  const VariantSelectionBottomSheet({
    super.key,
    required this.product,
  });

  static Future<void> show(BuildContext context, Product product) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => VariantSelectionBottomSheet(product: product),
    );
  }

  static Future<void> showForCard({
    required BuildContext context,
    required int productId,
    required String name,
    required double price,
    double? comparePrice,
    String? imageUrl,
    String? unit,
    bool inStock = true,
    Product? product,
  }) {
    final effectiveProduct = product ??
        Product(
          id: productId,
          name: name,
          slug: '',
          price: ProductPrice(amount: price, formatted: '', comparePrice: comparePrice),
          description: const ProductDescription(),
          inventory: ProductInventory(quantity: inStock ? 99 : 0, inStock: inStock, isLowStock: false),
          flags: const ProductFlags(isActive: true, isFeatured: false),
          unit: unit,
          primaryImage: imageUrl != null ? ProductImage(id: 0, url: imageUrl, isPrimary: true) : null,
        );
    return show(context, effectiveProduct);
  }

  @override
  State<VariantSelectionBottomSheet> createState() => _VariantSelectionBottomSheetState();
}

class _VariantSelectionBottomSheetState extends State<VariantSelectionBottomSheet> {
  late ProductVariant _selectedVariant;
  late List<ProductVariant> _effectiveVariants;
  int _quantity = 1;
  bool _isAdding = false;

  final Color _brandGreen = const Color(0xFF0C831F);

  @override
  void initState() {
    super.initState();
    final isInStock = widget.product.inventory.inStock;
    _effectiveVariants = widget.product.variants.isNotEmpty
        ? widget.product.variants
        : [
            ProductVariant(
              id: widget.product.id,
              name: widget.product.unit ?? 'Default',
              mrp: widget.product.price.comparePrice ?? widget.product.price.amount,
              sellingPrice: widget.product.price.amount,
              quantity: isInStock ? 99 : 0,
              isActive: isInStock,
              isDefault: true,
              image: widget.product.imageUrl,
            ),
          ];

    _selectedVariant = _effectiveVariants.firstWhere(
      (v) => v.isDefault && v.inStock,
      orElse: () => _effectiveVariants.firstWhere(
        (v) => v.inStock,
        orElse: () => _effectiveVariants.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variants = _effectiveVariants;

    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencyConfig = configState is AppConfigLoaded ? configState.config.currencyConfig : null;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Product Image, Title & Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CachedImage(
                        imageUrl: _selectedVariant.image ?? widget.product.imageUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1C),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.product.unit != null && widget.product.unit!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.product.unit!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Title: Available Variations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Options',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1C),
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${variants.length} options',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Variants List
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final variant = variants[index];
                  final isSelected = variant.id == _selectedVariant.id;

                  return GestureDetector(
                    onTap: variant.isSoldOut
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedVariant = variant);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _brandGreen.withValues(alpha: 0.05)
                            : (variant.isSoldOut ? Colors.grey.shade50 : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? _brandGreen
                              : (variant.isSoldOut ? Colors.grey.shade200 : Colors.grey.shade300),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Radio selection indicator
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? _brandGreen : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? _brandGreen : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Variant Name / Display attribute
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variant.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: variant.isSoldOut
                                        ? Colors.grey.shade400
                                        : const Color(0xFF1C1C1C),
                                  ),
                                ),
                                if (variant.isSoldOut) ...[
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Price & MRP
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.formatAmount(variant.sellingPrice, currencyConfig),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: variant.isSoldOut ? Colors.grey.shade400 : _brandGreen,
                                ),
                              ),
                              if (variant.mrp > variant.sellingPrice) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatAmount(variant.mrp, currencyConfig),
                                      style: TextStyle(
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${variant.discountPercent.toStringAsFixed(0)}% OFF',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Footer Action Bar: Quantity & Add to Cart Button
          Row(
            children: [
              // Quantity Stepper
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Add To Cart Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_selectedVariant.isSoldOut || _isAdding)
                        ? null
                        : () {
                            setState(() => _isAdding = true);
                            HapticFeedback.mediumImpact();

                            final isRealVariant = _selectedVariant.id != widget.product.id;
                            final variantName = _selectedVariant.displayName;
                            final fullProductName = isRealVariant
                                ? '${widget.product.name} ($variantName)'
                                : widget.product.name;

                            context.read<CartBloc>().add(
                              AddToCartEvent(
                                productId: widget.product.id,
                                variantId: isRealVariant ? _selectedVariant.id : null,
                                quantity: _quantity,
                                productName: fullProductName,
                                productImage: _selectedVariant.image ?? widget.product.imageUrl,
                                price: _selectedVariant.sellingPrice,
                              ),
                            );

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$fullProductName added to cart!'),
                                backgroundColor: _brandGreen,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'ADD ITEM  •  ${CurrencyFormatter.formatAmount(_selectedVariant.sellingPrice * _quantity, currencyConfig)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }
}
