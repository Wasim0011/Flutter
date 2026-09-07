import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/cached_image.dart';

import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../../../../core/widgets/inallcart_loader.dart';

class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const GlobalAppBar(
        title: 'My Orders',
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: InAllCartLoader());
          }

          if (state is OrdersError) {
            return _buildErrorState(context, state.message);
          }

          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildOrdersList(context, state.orders);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<OrdersBloc>().add(const RefreshOrders());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your order history will appear here\nonce you start ordering yummy food!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go(Routes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Start Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrdersBloc>().add(const RefreshOrders());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(context, order);
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    // Access global app config for currency/time
    final appConfig = context.read<AppConfigBloc>().currentConfig;
    final currencyConfig = appConfig?.currencyConfig;
    final timezoneConfig = appConfig?.timezoneConfig;

    // Formatting Date
    final localTime = order.timestamps.createdAt.toLocal();
    // Force standard date pattern to avoid config errors (e.g. '24/8/y')
    const datePattern = 'dd MMM yyyy'; 
    final is24Hour = timezoneConfig?.timeFormat == '24';
    final timePattern = is24Hour ? 'HH:mm' : 'hh:mm a';
    final formattedDate = DateFormat('$datePattern, $timePattern').format(localTime);

    // Status Logic
    final isDelivered = order.status.isDelivered;
    final canTrack = !order.status.isDelivered && !order.status.isCancelled; // Track all active orders

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToOrderDetail(context, order),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status + Price
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order ${order.status.label}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (isDelivered) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed at $formattedDate',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (canTrack) ...[
                            const SizedBox(height: 8),
                            // Removed header track chip
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatAmount(order.pricing.total, currencyConfig),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.keyboard_arrow_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ],
                ),
              ),

              // Items (Images)
              if (order.items.isNotEmpty)
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      final imageUrl = item.productImage != null
                          ? AppConstants.getFullMediaUrl(item.productImage!)
                          : '';
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: imageUrl.isNotEmpty
                            ? CachedImage(
                                imageUrl: imageUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.contain,
                                errorWidget: const Icon(Icons.image, size: 20, color: Colors.grey),
                              )
                            : const Icon(Icons.image, size: 20, color: Colors.grey),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Bottom Buttons Logic
              if (order.status.isCancelled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Text(
                    'Cancelled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                    ),
                  ),
                )
              else if (canTrack)
                 InkWell(
                  onTap: () => _navigateToTracking(context, order),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)), // Does this clip properly if parent has radius? Yes probably.
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      'Track Order',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else 
                Row(
                  children: [
                    // Rate Order - Only for delivered items
                    if (isDelivered) ...[
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push(
                            '/orders/${order.id}/review',
                            extra: order,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Rate Order',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey.shade200),
                    ],

                    // Reorder / Order Again
                    Expanded(
                      child: InkWell(
                        onTap: () => _handleReorder(context, order),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: const Text(
                            'Order Again',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary, 
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOrderDetail(BuildContext context, Order order) {
    context.push(
      Routes.order(order.id.toString()),
      extra: order,
    );
  }

  void _navigateToTracking(BuildContext context, Order order) {
    context.push(
      Routes.order(order.id.toString()),
      extra: order,
    );
  }

  void _handleReorder(BuildContext context, Order order) {
    // Optimistically add items. Check stock would require product fetch.
    int addedCount = 0;
    for (var item in order.items) {
      // Basic check: Don't add if we know it's invalid (e.g. negative qty?)
      if (item.quantity > 0) {
        context.read<CartBloc>().add(AddToCartEvent(
          productId: item.productId,
          quantity: item.quantity,
          productName: item.productName,
          productImage: item.productImage,
          price: item.price,
        ));
        addedCount++;
      }
    }
    
    if (addedCount > 0) {
      // Show global loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Simulate processing time/wait for Bloc updates
      Future.delayed(const Duration(seconds: 1), () {
        if (!context.mounted) return;
        
        // 1. Close loader (explicitly from root navigator where showDialog pushes)
        Navigator.of(context, rootNavigator: true).pop();
        
        // 2. Navigate to cart
        if (context.mounted) {
          context.push('/cart');
        }
      });
    }
  }

}
