import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/house_shifting_cubit.dart';
import '../widgets/hs_icons.dart';

class HsOrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;

  const HsOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<HsOrderDetailScreen> createState() => _HsOrderDetailScreenState();
}

class _HsOrderDetailScreenState extends State<HsOrderDetailScreen> {
  final HouseShiftingCubit _cubit = GetIt.I<HouseShiftingCubit>();
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _cubit.getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = result['order'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  /// Safely parse a value that may be String or num from the API.
  static double _n(dynamic v) =>
      double.tryParse(v?.toString() ?? '') ?? 0.0;

  static const Map<String, Color> _statusColors = {
    'delivered':  AppColors.success,
    'completed':  AppColors.success,
    'cancelled':  AppColors.error,
    'moving':     AppColors.info,
    'accepted':   AppColors.info,
    'enroute':    AppColors.info,
    'arrived':    AppColors.info,
    'pending':    AppColors.warning,
    'searching':  AppColors.warning,
  };

  Color _statusColor(String s) =>
      _statusColors[s.toLowerCase()] ?? AppColors.textSecondary;

  String _statusLabel(String s) =>
      s.replaceAll('_', ' ').toUpperCase();

  bool get _canCancel {
    final s = _order?['status']?.toString() ?? '';
    return ['pending', 'searching', 'accepted', 'enroute'].contains(s);
  }

  // ── Cancel dialog ─────────────────────────────────────────────────────────

  Future<void> _showCancelDialog() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please tell us why you want to cancel.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for cancellation…',
                hintStyle: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _cancelling = true);
      try {
        await _cubit.cancelOrder(
            widget.orderId, reasonCtrl.text.trim());
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _cancelling = false);
      }
    }
    reasonCtrl.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.orderNumber,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2),
        ),
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined,
                  size: 18, color: AppColors.textSecondary),
              tooltip: 'Copy order number',
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: widget.orderNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Order number copied'),
                      duration: Duration(seconds: 1)),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
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

  Widget _buildContent() {
    final o = _order!;
    final status      = o['status']?.toString() ?? 'pending';
    final color       = _statusColor(status);
    final pickup      = o['pickup_address']?.toString() ?? '-';
    final dropoff     = o['dropoff_address']?.toString() ?? '-';
    final symbol      = o['currency_symbol']?.toString() ?? '₹';
    final serviceType = o['service_type']?['name']?.toString() ?? '-';
    final provider    = o['provider']?['user']?['name']?.toString();
    final items       = (o['items'] as List? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final addons      = (o['addons'] as List? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final createdAt   = o['created_at']?.toString() ?? '';
    final dateStr     = createdAt.length >= 10
        ? createdAt.substring(0, 10)
        : createdAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Route card ───────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Route'),
                const SizedBox(height: 12),
                _RouteRow(
                  pickup: pickup,
                  dropoff: dropoff,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Service info ─────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Service Details'),
                const SizedBox(height: 12),
                // Service type with image
                Row(
                  children: [
                    _IconThumb(
                      iconUrl: o['service_type']?['icon_url']?.toString(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceType,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (provider != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Provider: $provider',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_n(o['helper_count']) > 0) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                      label: 'Helpers',
                      value: '${o['helper_count']} helper(s)'),
                ],
                if (o['special_instructions'] != null &&
                    (o['special_instructions'] as String?)!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                      label: 'Instructions',
                      value: o['special_instructions'].toString()),
                ],
              ],
            ),
          ),

          // ── Items ────────────────────────────────────────────────────────
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Items'),
                  const SizedBox(height: 12),
                  ...items.map((item) {
                    final name = item['item']?['name']?.toString() ??
                        item['item_name']?.toString() ??
                        '-';
                    final qty      = item['quantity']?.toString() ?? '1';
                    final iconUrl  = item['item']?['icon_url']?.toString() ??
                        item['item']?['category']?['icon_url']?.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          _IconThumb(iconUrl: iconUrl, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x$qty',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Add-ons ──────────────────────────────────────────────────────
          if (addons.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Add-on Services'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: addons.map((a) {
                      final name = a['addon_name']?.toString() ??
                          a['addon']?['name']?.toString() ??
                          '-';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Pricing breakdown ────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Price Breakdown'),
                const SizedBox(height: 12),
                _PriceRow(
                    label: 'Base Fee',
                    value: '$symbol${o['base_fee'] ?? '-'}'),
                if (_n(o['distance_fee']) > 0)
                  _PriceRow(
                      label: 'Distance Fee',
                      value: '$symbol${o['distance_fee']}'),
                if (_n(o['item_surcharge']) > 0)
                  _PriceRow(
                      label: 'Item Surcharge',
                      value: '$symbol${o['item_surcharge']}'),
                if (_n(o['floor_surcharge']) > 0)
                  _PriceRow(
                      label: 'Floor Surcharge',
                      value: '$symbol${o['floor_surcharge']}'),
                if (_n(o['helper_fee']) > 0)
                  _PriceRow(
                      label: 'Helper Fee',
                      value: '$symbol${o['helper_fee']}'),
                if (_n(o['addon_total']) > 0)
                  _PriceRow(
                      label: 'Add-ons',
                      value: '$symbol${o['addon_total']}'),
                if (_n(o['surge_amount']) > 0)
                  _PriceRow(
                      label: 'Surge',
                      value: '$symbol${o['surge_amount']}',
                      valueColor: AppColors.warning),
                if (_n(o['discount_amount']) > 0)
                  _PriceRow(
                      label: 'Discount',
                      value: '-$symbol${o['discount_amount']}',
                      valueColor: AppColors.success),
                if (_n(o['tax_amount']) > 0)
                  _PriceRow(
                      label: 'Tax',
                      value: '$symbol${o['tax_amount']}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      '$symbol${o['total_amount'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      (o['payment_method']?.toString() ?? '-')
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Cancel button ────────────────────────────────────────────────
          if (_canCancel) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _cancelling ? null : _showCancelDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _cancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.error),
                      )
                    : const Text(
                        'Cancel Order',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _PriceRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String pickup;
  final String dropoff;
  const _RouteRow({required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 3),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              ),
            ),
            Container(width: 1.5, height: 28, color: AppColors.border),
            const Icon(Icons.location_on_rounded,
                size: 14, color: AppColors.error),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.3),
              ),
              const SizedBox(height: 20),
              Text(
                dropoff,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small square thumbnail — shows network image if [iconUrl] is set,
/// otherwise shows placeholder.svg.
class _IconThumb extends StatelessWidget {
  final String? iconUrl;
  final double size;

  const _IconThumb({this.iconUrl, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        iconUrl != null && iconUrl!.isNotEmpty && iconUrl!.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: hasImage
          ? Image.network(
              iconUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(size * 0.22),
      child: SvgPicture.asset(HsIcons.placeholder),
    );
  }
}
