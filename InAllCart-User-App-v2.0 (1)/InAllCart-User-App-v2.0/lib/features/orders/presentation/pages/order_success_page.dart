import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/storage_service.dart';
import '../../../popups/domain/services/popup_manager.dart';
import '../../../popups/presentation/widgets/popup_overlay_dialog.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/order.dart';

class OrderSuccessPage extends StatefulWidget {
  final Order order;

  const OrderSuccessPage({super.key, required this.order});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  Order get order => widget.order;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOrderSuccessPopup();
    });
  }

  void _checkOrderSuccessPopup() async {
    final popupManager = getIt<PopupManager>();
    final storage = getIt<StorageService>();
    final userData = storage.getUser();
    final isVipUser = userData?['is_vip'] == true || userData?['vip_status'] == 'active';
    final lang = storage.getLanguage() ?? 'en';

    final popup = await popupManager.evaluateEligiblePopup(
      contextTrigger: PopupContextTrigger.onOrderCompletion,
      isUserLoggedIn: true,
      isVipUser: isVipUser,
      currentLanguage: lang,
    );

    if (popup != null && mounted) {
      await popupManager.recordPopupPresented(popup);
      if (mounted) {
        PopupOverlayDialog.show(context, popup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Lottie animation
                    Lottie.asset(
                      'assets/icons/ordersucess.json',
                      width: 200,
                      height: 200,
                      repeat: false,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Order Placed!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your order has been confirmed',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Order summary card
                    _Card(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.tag_rounded,
                            label: 'Order Number',
                            value: order.orderNumber,
                            valueBold: true,
                          ),
                          _divider(),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: DateFormat('MMM dd, yyyy').format(order.timestamps.createdAt),
                          ),
                          _divider(),
                          _InfoRow(
                            icon: Icons.payment_rounded,
                            label: 'Payment',
                            value: _formatPaymentMethod(order.payment.method),
                          ),
                          _divider(),
                          _InfoRow(
                            icon: Icons.receipt_long_rounded,
                            label: 'Total',
                            value: CurrencyFormatter.formatAmount(order.pricing.total, null),
                            valueBold: true,
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delivery address
                    if (order.address != null) ...[
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              icon: Icons.location_on_rounded,
                              label: 'Delivery Address',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              order.address!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.address!.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.address!.addressLine1}, ${order.address!.city}, '
                              '${order.address!.state} ${order.address!.postalCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Order items
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.shopping_bag_rounded,
                            label: 'Items (${order.items.length})',
                          ),
                          const SizedBox(height: 12),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${item.productName} × ${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatAmount(item.total, null),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notification info banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You\'ll receive updates via notifications',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.go(Routes.order(order.id.toString()), extra: order),
                      icon: const Icon(Icons.local_shipping_rounded, size: 20),
                      label: const Text(
                        'Track Order',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => context.go(Routes.home),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _divider() => const Divider(height: 20, thickness: 0.8);

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'Wallet';
      case 'razorpay':
        return 'Razorpay';
      case 'stripe':
        return 'Stripe';
      case 'paystack':
        return 'Paystack';
      case 'flutterwave':
        return 'Flutterwave';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      default:
        return method;
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
