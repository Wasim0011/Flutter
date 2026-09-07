import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/house_shifting_cubit.dart';
import 'hs_order_detail_screen.dart';

class HsOrdersScreen extends StatefulWidget {
  const HsOrdersScreen({super.key});

  @override
  State<HsOrdersScreen> createState() => _HsOrdersScreenState();
}

class _HsOrdersScreenState extends State<HsOrdersScreen> {
  final HouseShiftingCubit _cubit = GetIt.I<HouseShiftingCubit>();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; _page = 1; });
    try {
      final result = await _cubit.getOrders(page: 1);
      final pagination = result['orders'] as Map<String, dynamic>? ?? {};
      final list = (pagination['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) {
        setState(() {
          _orders = list;
          _loading = false;
          _hasMore = (pagination['current_page'] as int? ?? 1) <
              (pagination['last_page'] as int? ?? 1);
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final result = await _cubit.getOrders(page: _page + 1);
      final pagination = result['orders'] as Map<String, dynamic>? ?? {};
      final list = (pagination['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) {
        setState(() {
          _page++;
          _orders.addAll(list);
          _loadingMore = false;
          _hasMore = (pagination['current_page'] as int? ?? 1) <
              (pagination['last_page'] as int? ?? 1);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Shifting Orders',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadOrders)
              : _orders.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadOrders,
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: _orders.length + (_loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          if (i == _orders.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            );
                          }
                          return _OrderCard(
                            order: _orders[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HsOrderDetailScreen(
                                  orderId: _orders[i]['id'] as int,
                                  orderNumber: _orders[i]['order_number']
                                          ?.toString() ??
                                      '#${_orders[i]['id']}',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  static const Map<String, Color> _statusColors = {
    'delivered':   AppColors.success,
    'completed':   AppColors.success,
    'cancelled':   AppColors.error,
    'in_progress': AppColors.info,
    'moving':      AppColors.info,
    'assigned':    AppColors.info,
    'accepted':    AppColors.info,
    'enroute':     AppColors.info,
    'arrived':     AppColors.info,
    'pending':     AppColors.warning,
    'searching':   AppColors.warning,
  };

  Color _statusColor(String s) =>
      _statusColors[s.toLowerCase()] ?? AppColors.textSecondary;

  String _statusLabel(String s) =>
      s.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final status        = order['status']?.toString() ?? 'pending';
    final orderNumber   = order['order_number']?.toString() ?? '#${order['id']}';
    final total         = order['total_amount']?.toString() ?? '-';
    final symbol        = order['currency_symbol']?.toString() ?? '₹';
    final createdAt     = order['created_at']?.toString() ?? '';
    final pickup        = order['pickup_address']?.toString() ?? '-';
    final dropoff       = order['dropoff_address']?.toString() ?? '-';
    final serviceType   = order['service_type']?['name']?.toString();
    final color         = _statusColor(status);
    final dateStr       = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.03),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (serviceType != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            serviceType,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),

              // ── Route ────────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 2),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 2),
                        ),
                      ),
                      Container(
                          width: 1.5, height: 22, color: AppColors.border),
                      const Icon(Icons.location_on_rounded,
                          size: 12, color: AppColors.error),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickup,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.3),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          dropoff,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // ── Footer ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$symbol$total',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your shifting orders will appear here',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
