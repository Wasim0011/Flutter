import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../domain/entities/cart.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variantName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.variantName!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                BlocBuilder<AppConfigBloc, AppConfigState>(
                  builder: (context, state) {
                    final config = state is AppConfigLoaded ? state.config : null;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (item.hasDiscount) ...[
                          Text(
                            CurrencyFormatter.formatAmount(item.comparePrice! * item.quantity, config?.currencyConfig),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          CurrencyFormatter.formatAmount(item.price * item.quantity, config?.currencyConfig),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (!item.inStock) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Out of stock',
                      style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          item.inStock ? _buildQuantityControls() : _NotifyButton(productName: item.productName),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 68,
            height: 68,
            child: item.productImage != null && item.productImage!.isNotEmpty
                ? CachedImage(imageUrl: item.productImage!, width: 68, height: 68, fit: BoxFit.cover)
                : Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 26),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
              ),
              child: const Icon(Icons.close, size: 11, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyBtn(Icons.remove, onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          _buildQtyBtn(Icons.add, onIncrement),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 15, color: AppColors.primary),
      ),
    );
  }
}

/// Animated "Notify Me" button for out-of-stock items
class _NotifyButton extends StatefulWidget {
  final String productName;
  const _NotifyButton({required this.productName});

  @override
  State<_NotifyButton> createState() => _NotifyButtonState();
}

class _NotifyButtonState extends State<_NotifyButton>
    with SingleTickerProviderStateMixin {
  bool _notified = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (_notified) return;
    HapticFeedback.lightImpact();
    await _controller.forward();
    await _controller.reverse();
    setState(() => _notified = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You'll be notified when ${widget.productName} is back in stock",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _notified
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _notified ? AppColors.success : AppColors.error.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _notified
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_rounded,
                size: 14,
                color: _notified ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                _notified ? 'Notified' : 'Notify',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _notified ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
