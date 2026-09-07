import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../bloc/cart_bloc.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  List<_CouponItem> _coupons = [];
  bool _loading = true;
  String? _error;
  String? _applying;
  /// Inline error shown when a coupon application fails — displayed inside
  /// the sheet so the user sees the reason without the sheet being dismissed.
  String? _applyError;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      final client = getIt<ApiClient>();
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.coupons);
      final list = (response['data'] as List? ?? [])
          .map((e) => _CouponItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _coupons = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  /// Apply a coupon and wait for the BLoC to settle before deciding whether
  /// to close the sheet.
  ///
  /// Previous behaviour: fired the event then popped after a fixed 400 ms
  /// delay — the sheet closed before the server responded, so any error
  /// (expired coupon, min-order not met, etc.) surfaced as a floating snackbar
  /// with no context about which coupon failed.
  ///
  /// New behaviour: listens to the CartBloc stream and only pops on success
  /// (CartLoaded). On CartError it stays open and shows the error inline.
  void _apply(BuildContext context, String code) async {
    if (!mounted) return;
    setState(() {
      _applying = code;
      _applyError = null;
    });
    HapticFeedback.lightImpact();

    final cartBloc = context.read<CartBloc>();
    cartBloc.add(ApplyCouponEvent(code));

    // Wait for the BLoC to emit a terminal state for this operation.
    // We listen to the stream directly so we don't need a BlocListener here.
    await for (final state in cartBloc.stream) {
      if (!mounted) break;

      if (state is CartLoaded) {
        // Success — close the sheet.
        Navigator.of(context).pop(code);
        break;
      }

      if (state is CartError) {
        // Failure — stay open, show the error inline, reset spinner.
        setState(() {
          _applying = null;
          _applyError = state.message;
        });
        break;
      }

      // CartUpdating / CartSyncing — still in-flight, keep waiting.
    }

    // Safety: if we somehow exit the loop without resetting (e.g. widget
    // disposed mid-flight), clear the spinner so it doesn't get stuck.
    if (mounted && _applying == code) {
      setState(() => _applying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appliedCode = context.watch<CartBloc>().state.cart.couponCode;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Coupons',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // Manual entry
          _ManualCouponEntry(onApply: (code) => _apply(context, code)),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // Inline apply-error banner — shown when the server rejects a coupon.
          // Stays visible inside the sheet so the user knows exactly what failed.
          if (_applyError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _applyError!,
                      style: TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _applyError = null),
                    child: Icon(Icons.close, size: 16, color: AppColors.error),
                  ),
                ],
              ),
            ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Could not load coupons', style: TextStyle(color: Colors.grey[500])))
                    : _coupons.isEmpty
                        ? Center(child: Text('No coupons available', style: TextStyle(color: Colors.grey[500])))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _coupons.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF5F5F5)),
                            itemBuilder: (context, i) {
                              final c = _coupons[i];
                              final isApplied = appliedCode == c.code;
                              return _CouponTile(
                                coupon: c,
                                isApplied: isApplied,
                                isApplying: _applying == c.code,
                                onTap: isApplied ? null : () => _apply(context, c.code),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Manual entry ──────────────────────────────────────────────────────────────

class _ManualCouponEntry extends StatefulWidget {
  final void Function(String code) onApply;
  const _ManualCouponEntry({required this.onApply});

  @override
  State<_ManualCouponEntry> createState() => _ManualCouponEntryState();
}

class _ManualCouponEntryState extends State<_ManualCouponEntry> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                hintStyle: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            width: 90,
            child: ElevatedButton(
              onPressed: () {
                final code = _ctrl.text.trim();
                if (code.isNotEmpty) widget.onApply(code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coupon tile ───────────────────────────────────────────────────────────────

class _CouponTile extends StatelessWidget {
  final _CouponItem coupon;
  final bool isApplied;
  final bool isApplying;
  final VoidCallback? onTap;

  const _CouponTile({
    required this.coupon,
    required this.isApplied,
    required this.isApplying,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final config = configState is AppConfigLoaded ? configState.config.currencyConfig : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isApplied
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  size: 18,
                  color: isApplied ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isApplied
                                ? AppColors.success.withValues(alpha: 0.1)
                                : const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isApplied
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            coupon.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isApplied ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ),
                        if (coupon.isFirstOrderOnly) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'New user',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.subtitle(config),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (coupon.expiresAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Expires ${coupon.expiresAt}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Apply button
              if (isApplied)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                )
              else
                TextButton(
                  onPressed: isApplying ? null : onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isApplying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _CouponItem {
  final int id;
  final String code;
  final String name;
  final String type;
  final double value;
  final double? minOrderAmount;
  final double? maxDiscount;
  final String? expiresAt;
  final bool isFirstOrderOnly;

  const _CouponItem({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscount,
    this.expiresAt,
    required this.isFirstOrderOnly,
  });

  factory _CouponItem.fromJson(Map<String, dynamic> json) => _CouponItem(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        value: (json['value'] as num).toDouble(),
        minOrderAmount: json['min_order_amount'] != null ? (json['min_order_amount'] as num).toDouble() : null,
        maxDiscount: json['max_discount'] != null ? (json['max_discount'] as num).toDouble() : null,
        expiresAt: json['expires_at'] as String?,
        isFirstOrderOnly: json['is_first_order_only'] as bool? ?? false,
      );

  String subtitle(dynamic config) {
    final parts = <String>[];
    switch (type) {
      case 'percentage':
        final s = '${value.toInt()}% off';
        parts.add(maxDiscount != null
            ? '$s (up to ${CurrencyFormatter.formatAmount(maxDiscount!, config)})'
            : s);
        break;
      case 'fixed':
        parts.add('${CurrencyFormatter.formatAmount(value, config)} off');
        break;
      case 'free_delivery':
        parts.add('Free delivery');
        break;
    }
    if (minOrderAmount != null) {
      parts.add('Min order ${CurrencyFormatter.formatAmount(minOrderAmount!, config)}');
    }
    return parts.join(' · ');
  }
}
