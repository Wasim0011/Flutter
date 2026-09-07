import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../domain/entities/cart.dart';

class CartSummaryCard extends StatelessWidget {
  final CartSummary summary;
  final String? couponCode;
  final double? couponDiscount;
  final VoidCallback? onApplyCoupon;
  final VoidCallback? onRemoveCoupon;
  final VoidCallback? onCheckout;
  final bool isLoading;

  const CartSummaryCard({
    super.key,
    required this.summary,
    this.couponCode,
    this.couponDiscount,
    this.onApplyCoupon,
    this.onRemoveCoupon,
    this.onCheckout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final config = configState is AppConfigLoaded ? configState.config.currencyConfig : null;
        final totalSavings = summary.discount + (couponDiscount ?? 0);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Cart Summary header
                const Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Cart Summary',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bill rows
                _buildRow('Item Total', summary.subtotal, config),
                if (summary.discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildRow('Product Discount', -summary.discount, config, isDiscount: true),
                ],
                if (couponDiscount != null && couponDiscount! > 0) ...[
                  const SizedBox(height: 8),
                  _buildRow('Coupon ($couponCode)', -couponDiscount!, config, isDiscount: true),
                ],
                const SizedBox(height: 8),
                summary.deliveryCharge == 0
                    ? _buildFreeDeliveryRow()
                    : _buildRow('Delivery Fee', summary.deliveryCharge, config),
                if (summary.tax > 0) ...[
                  const SizedBox(height: 8),
                  _buildRow('Taxes & Charges', summary.tax, config),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                ),

                // To Pay row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'To Pay',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (totalSavings > 0) ...[
                          Text(
                            CurrencyFormatter.formatAmount(summary.totalWithDelivery + totalSavings, config),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          CurrencyFormatter.formatAmount(summary.totalWithDelivery, config),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),

                // Savings pill
                if (totalSavings > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_offer_rounded, size: 13, color: AppColors.success),
                        const SizedBox(width: 5),
                        const Text('You\'re saving ', style: TextStyle(fontSize: 12, color: AppColors.success)),
                        Text(
                          CurrencyFormatter.formatAmount(totalSavings, config),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                        const Text(' on this order', style: TextStyle(fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Checkout button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Proceed to Checkout',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, double amount, CurrencyConfig? config, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          isDiscount
              ? '- ${CurrencyFormatter.formatAmount(amount.abs(), config)}'
              : CurrencyFormatter.formatAmount(amount, config),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFreeDeliveryRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Delivery Fee', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text('FREE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
      ],
    );
  }
}
