import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../domain/entities/delivery_tracking.dart';
import '../../domain/entities/order.dart';
import '../bloc/delivery_tracking_bloc.dart';
import '../bloc/delivery_tracking_event.dart';
import '../bloc/delivery_tracking_state.dart';
import '../widgets/delivery_map_widget.dart';
import '../widgets/delivery_partner_card.dart';
import '../../../support/presentation/screens/support_tickets_screen.dart';

class OrderDetailPage extends StatefulWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  DeliveryTrackingBloc? _trackingBloc;
  bool _isMapExpanded = false;

  /// Show tracking section for all non-terminal orders
  bool get _showTracking =>
      !widget.order.status.isDelivered && !widget.order.status.isCancelled;

  /// Active in-transit statuses that need live polling
  bool get _isActiveDelivery =>
      widget.order.status.isPickedUp || widget.order.status.isOutForDelivery;

  @override
  void initState() {
    super.initState();
    if (_showTracking) {
      _trackingBloc = getIt<DeliveryTrackingBloc>()
        ..add(LoadDeliveryTracking(orderId: widget.order.id));
      if (_isActiveDelivery) {
        _trackingBloc!.add(StartTrackingPolling(widget.order.id));
      }
    }
  }

  @override
  void dispose() {
    _trackingBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.read<AppConfigBloc>().currentConfig;
    final currencyConfig = appConfig?.currencyConfig;
    final timezoneConfig = appConfig?.timezoneConfig;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.orders);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tracking section ──────────────────────────────────────
            if (_showTracking && _trackingBloc != null)
              BlocProvider.value(
                value: _trackingBloc!,
                child: BlocBuilder<DeliveryTrackingBloc, DeliveryTrackingState>(
                  builder: (context, state) {
                    if (state is DeliveryTrackingLoaded) {
                      return _buildTrackingSection(context, state);
                    }
                    if (state is DeliveryTrackingLoading) {
                      return _buildTrackingPlaceholder();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

            const SizedBox(height: 24),
            _buildStatusBanner(widget.order.status),
            if (!widget.order.status.isDelivered && !widget.order.status.isCancelled) ...[
              const SizedBox(height: 16),
              _buildDeliveryOtpCard(
                (widget.order.deliveryOtp != null && widget.order.deliveryOtp!.isNotEmpty)
                    ? widget.order.deliveryOtp!
                    : (widget.order.id % 10000).toString().padLeft(4, '0'),
              ),
            ],
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${widget.order.items.length} items in order',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildItemsList(currencyConfig),

            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 24),

            _buildBillSummary(currencyConfig),

            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 24),

            _buildOrderDetails(context, timezoneConfig),

            const SizedBox(height: 40),
            _buildHelpBottomBar(context),
            if (widget.order.status.isDelivered) ...[
              const SizedBox(height: 12),
              _buildRateOrderButton(context),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }

  // ── Tracking section ──────────────────────────────────────────────────

  Widget _buildTrackingSection(BuildContext context, DeliveryTrackingLoaded state) {
    final hasMedia = state.tracking.trackingMedia.isNotEmpty;

    return Column(
      children: [
        // Media carousel OR map
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _isMapExpanded
              ? _buildExpandedMap(state, hasMedia)
              : (hasMedia
                  ? _buildMediaCarousel(state)
                  : _buildCompactMap(state)),
        ),

        // Store card
        if (state.tracking.store != null)
          _buildStoreCard(state.tracking.store!),

        // Delivery partner card
        if (state.tracking.deliveryPartner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DeliveryPartnerCard(
              partner: state.tracking.deliveryPartner!,
              currentLocation: state.tracking.currentLocation,
              onCall: () async {
                final phone = state.tracking.deliveryPartner?.phone;
                if (phone != null && phone.isNotEmpty) {
                  final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                }
              },
              onMessage: () => context.push(
                '/orders/${widget.order.id}/chat/customer_delivery',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaCarousel(DeliveryTrackingLoaded state) {
    return SizedBox(
      key: const ValueKey('media'),
      height: 300,
      child: Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 300,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              enableInfiniteScroll: state.tracking.trackingMedia.length > 1,
            ),
            items: state.tracking.trackingMedia.map((media) {
              return media.image != null
                  ? CachedImage(
                      imageUrl: AppConstants.getFullMediaUrl(media.image!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                    )
                  : Container(color: Colors.grey[200]);
            }).toList(),
          ),
          // Map thumbnail bottom-right — static icon to avoid double map rendering
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _isMapExpanded = true),
              child: Container(
                width: 110,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(height: 4),
                    const Text(
                      'VIEW MAP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedMap(DeliveryTrackingLoaded state, bool hasMedia) {
    return SizedBox(
      key: const ValueKey('map'),
      height: 280,
      child: Stack(
        children: [
          DeliveryMapWidget(tracking: state.tracking, history: null),
          if (hasMedia)
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => setState(() => _isMapExpanded = false),
                child: _buildPiPContainer(
                  child: state.tracking.trackingMedia.first.image != null
                      ? CachedImage(
                          imageUrl: AppConstants.getFullMediaUrl(
                              state.tracking.trackingMedia.first.image!),
                          fit: BoxFit.cover,
                          width: 110,
                          height: 90,
                        )
                      : Container(color: Colors.grey[300]),
                  label: 'VIEW OFFERS',
                  icon: Icons.image_outlined,
                  iconColor: Colors.purple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactMap(DeliveryTrackingLoaded state) {
    return Container(
      key: const ValueKey('compact'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DeliveryMapWidget(tracking: state.tracking, history: null),
      ),
    );
  }

  Widget _buildPiPContainer({
    required Widget child,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 110,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(DeliveryStore store) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: store.image != null
                ? CachedImage(
                    imageUrl: AppConstants.getFullMediaUrl(store.image!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                if (store.phone != null)
                  Text(store.phone!,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          if (store.phone != null && store.phone!.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: store.phone);
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone, color: AppColors.primary, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingPlaceholder() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 240,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
        ),
        onPressed: () => context.canPop() ? context.pop() : context.go(Routes.orders),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.orderNumber}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${widget.order.items.length} items',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportTicketsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 16, color: Color(0xFFE91E63)),
                  SizedBox(width: 6),
                  Text(
                    'Get Help',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Status banner ───────────────────────────────────────────────────────

  Widget _buildStatusBanner(OrderStatus status) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    if (status.isDelivered) {
      bgColor = const Color(0xFFF0FDF4);
      iconColor = AppColors.success;
      icon = Icons.check_circle_outline;
    } else if (status.isCancelled) {
      bgColor = const Color(0xFFFEF2F2);
      iconColor = AppColors.error;
      icon = Icons.cancel_outlined;
    } else {
      bgColor = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFFF9800);
      icon = Icons.shopping_bag_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              status.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delivery OTP card ───────────────────────────────────────────────────

  Widget _buildDeliveryOtpCard(String otp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFF9100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.key_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Verification OTP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Share code with delivery partner upon arrival',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: otp.split('').map((char) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Text(
                        char,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE65100),
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: otp));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery OTP copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_rounded, color: Color(0xFFE65100), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Items list ──────────────────────────────────────────────────────────

  Widget _buildItemsList(dynamic currencyConfig) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.order.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final item = widget.order.items[index];
        final imageUrl = item.productImage != null
            ? AppConstants.getFullMediaUrl(item.productImage!)
            : '';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? CachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget:
                            const Icon(Icons.image, size: 16, color: Colors.grey),
                      )
                    : const Icon(Icons.image, size: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variantName != null && item.variantName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.variantName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} unit',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatAmount(item.total, currencyConfig),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Bill summary ────────────────────────────────────────────────────────

  Widget _buildBillSummary(dynamic currencyConfig) {
    final pricing = widget.order.pricing;
    final savings = pricing.discount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 20, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Bill Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Item Total', pricing.subtotal, currencyConfig),
          const SizedBox(height: 12),
          _buildSummaryRow('Delivery Fee', pricing.deliveryFee, currencyConfig,
              isFree: pricing.deliveryFee == 0),
          if (pricing.driverTip > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow('Rider Tip (100% to Rider)', pricing.driverTip, currencyConfig),
          ],
          if (pricing.tax > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow('Tax', pricing.tax, currencyConfig),
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Bill',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (savings > 0)
                        Text(
                          CurrencyFormatter.formatAmount(
                              pricing.subtotal +
                                  pricing.deliveryFee +
                                  pricing.tax +
                                  pricing.driverTip,
                              currencyConfig),
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (savings > 0) const SizedBox(width: 6),
                      Text(
                        CurrencyFormatter.formatAmount(
                            pricing.total, currencyConfig),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (savings > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SAVED ${CurrencyFormatter.formatAmount(savings, currencyConfig)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Incl. all taxes and charges',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, dynamic currencyConfig,
      {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        isFree
            ? const Text('FREE',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success))
            : Text(
                CurrencyFormatter.formatAmount(amount, currencyConfig),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
      ],
    );
  }

  // ── Order details ───────────────────────────────────────────────────────

  Widget _buildOrderDetails(BuildContext context, dynamic timezoneConfig) {
    final localTime = widget.order.timestamps.createdAt.toLocal();
    const datePattern = 'dd MMM yyyy';
    final is24Hour = timezoneConfig?.timeFormat == '24';
    final timePattern = is24Hour ? 'HH:mm' : 'hh:mm a';
    final formattedDate =
        DateFormat('$datePattern, $timePattern').format(localTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailItem(
            label: 'Order ID',
            value: '#${widget.order.orderNumber}',
            showCopy: true,
            onCopy: () {
              Clipboard.setData(
                  ClipboardData(text: widget.order.orderNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Order ID copied'),
                    duration: Duration(seconds: 1)),
              );
            },
          ),
          const SizedBox(height: 20),
          if (widget.order.address != null)
            _buildDetailItem(
              label: 'Delivery Address',
              value: widget.order.address!.fullAddress,
            ),
          const SizedBox(height: 20),
          _buildDetailItem(
            label: 'Order Placed at',
            value: formattedDate,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    bool showCopy = false,
    VoidCallback? onCopy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            if (showCopy)
              InkWell(
                onTap: onCopy,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.copy, size: 16, color: AppColors.primary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildDivider() =>
      Container(height: 8, color: const Color(0xFFF8F9FA));

  Widget _buildHelpBottomBar(BuildContext context) {
    final isDelivered = widget.order.status.isDelivered;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SupportTicketsScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.help_outline_rounded,
                size: 20, color: Color(0xFFE91E63)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need help with this order?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDelivered ? 'Contact support for help with this order' : 'Find your issue or reach out via chat',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRateOrderButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push(
          '/orders/${widget.order.id}/review',
          extra: widget.order,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.star_rounded, size: 22, color: Colors.white),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate this order',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Share your experience with the products',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.chevron_right, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
