import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/app_config/domain/entities/app_config.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import '../theme/ride_colors.dart';

/// Vehicle selection bottom sheet — Uber-style dark card list.
/// Shows route summary, distance/duration, surge badge,
/// vehicle cards, promo code, payment method, and book button.
class RideVehicleSelectionSheet extends StatelessWidget {
  final String? pickupAddress;
  final String? destinationAddress;
  final List<VehicleType> vehicleTypes;
  final List<FareEstimate> fareEstimates;
  final int selectedIndex;
  final String paymentMethod;
  final List<PaymentMethodInfo> availablePaymentMethods;
  final String? promoCode;
  final bool isLoading;
  final CurrencyConfig currency;

  final ValueChanged<int> onVehicleSelected;
  final VoidCallback onEditRoute;
  final VoidCallback onPaymentTap;
  final VoidCallback onPromoTap;
  final VoidCallback onPromoRemove;
  final VoidCallback onBook;

  const RideVehicleSelectionSheet({
    super.key,
    this.pickupAddress,
    this.destinationAddress,
    required this.vehicleTypes,
    required this.fareEstimates,
    required this.selectedIndex,
    required this.paymentMethod,
    required this.availablePaymentMethods,
    this.promoCode,
    required this.isLoading,
    required this.currency,
    required this.onVehicleSelected,
    required this.onEditRoute,
    required this.onPaymentTap,
    required this.onPromoTap,
    required this.onPromoRemove,
    required this.onBook,
  });

  FareEstimate? _estimateFor(String name) {
    try {
      return fareEstimates.firstWhere((e) => e.vehicleType == name);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (vehicleTypes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No vehicles available in your area.',
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
        ),
      );
    }

    final safeIndex = selectedIndex.clamp(0, vehicleTypes.length - 1);
    final selectedVehicle = vehicleTypes[safeIndex];
    final selectedEstimate = _estimateFor(selectedVehicle.name);
    final selectedFare = selectedEstimate?.totalFare ?? selectedVehicle.baseFare;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Route summary ─────────────────────────────────────────────
        _RouteSummaryBar(
          pickupAddress: pickupAddress,
          destinationAddress: destinationAddress,
          estimate: selectedEstimate,
          onTap: onEditRoute,
        ),

        const SizedBox(height: 4),

        // ── Vehicle list ──────────────────────────────────────────────
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: vehicleTypes.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleTypes[index];
              final estimate = _estimateFor(vehicle.name);
              final fare = estimate?.totalFare ?? vehicle.baseFare;
              final isSelected = safeIndex == index;
              return _VehicleCard(
                vehicle: vehicle,
                estimate: estimate,
                fare: fare,
                isSelected: isSelected,
                currency: currency,
                onTap: () => onVehicleSelected(index),
              );
            },
          ),
        ),

        // ── Promo code ────────────────────────────────────────────────
        _PromoRow(
          promoCode: promoCode,
          onTap: onPromoTap,
          onRemove: onPromoRemove,
        ),

        // ── Payment method ────────────────────────────────────────────
        _PaymentRow(
          paymentMethod: paymentMethod,
          availableMethods: availablePaymentMethods,
          onTap: onPaymentTap,
        ),

        // ── Book button ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: RideColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: Colors.grey[200],
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Book ${selectedVehicle.name}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          selectedFare > 0
                              ? currency.formatAmount(selectedFare)
                              : '',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Route summary bar ─────────────────────────────────────────────────

class _RouteSummaryBar extends StatelessWidget {
  final String? pickupAddress;
  final String? destinationAddress;
  final FareEstimate? estimate;
  final VoidCallback onTap;

  const _RouteSummaryBar({
    this.pickupAddress,
    this.destinationAddress,
    this.estimate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.green),
                      ),
                      Container(
                          height: 14, width: 1.5, color: Color(0xFFDDDDDD)),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupAddress ?? 'Current Location',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          destinationAddress ?? 'Destination',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined,
                      size: 15, color: Colors.black38),
                ],
              ),
              if (estimate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.route_outlined,
                        size: 13, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      '${estimate!.estimatedDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_outlined,
                        size: 13, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      '${estimate!.estimatedDuration.toInt()} min',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                    if (estimate!.isSurgeActive) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt,
                                size: 11, color: Colors.orange),
                            Text(
                              '${estimate!.surgeMultiplier.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vehicle card ──────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleType vehicle;
  final FareEstimate? estimate;
  final double fare;
  final bool isSelected;
  final CurrencyConfig currency;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    this.estimate,
    required this.fare,
    required this.isSelected,
    required this.currency,
    required this.onTap,
  });

  IconData _icon() {
    final n = vehicle.name.toLowerCase();
    if (n.contains('bike') || n.contains('moto')) return Icons.two_wheeler;
    if (n.contains('auto')) return Icons.local_taxi;
    if (n.contains('xl') || n.contains('suv')) return Icons.airport_shuttle;
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? RideColors.accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? RideColors.accent : const Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: RideColors.accent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Vehicle icon / image
            SizedBox(
              width: 52,
              height: 38,
              child: vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty
                  ? Image.network(
                      AppConstants.getFullMediaUrl(vehicle.iconUrl!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        _icon(),
                        size: 34,
                        color: isSelected ? RideColors.primary : Colors.black87,
                      ),
                    )
                  : Icon(
                      _icon(),
                      size: 34,
                      color: isSelected ? RideColors.primary : Colors.black87,
                    ),
            ),
            const SizedBox(width: 12),

            // Name + ETA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.person,
                          size: 12, color: Colors.black38),
                      Text(
                        '${vehicle.capacity}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estimate != null
                        ? '${estimate!.estimatedDuration.toInt()} min away'
                        : vehicle.description ?? 'Affordable rides',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Fare + surge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fare > 0 ? currency.formatAmount(fare) : '—',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                if (estimate != null && estimate!.isSurgeActive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 11, color: Colors.orange),
                      const Text(
                        'Surge',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Promo row ─────────────────────────────────────────────────────────

class _PromoRow extends StatelessWidget {
  final String? promoCode;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PromoRow({
    this.promoCode,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final applied = promoCode != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: applied
                ? Colors.green.withOpacity(0.05)
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: applied ? Colors.green : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: applied ? Colors.green : Colors.black38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  applied ? 'Promo applied: $promoCode' : 'Add promo code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: applied ? Colors.green : Colors.black87,
                  ),
                ),
              ),
              if (applied)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 20, color: Colors.red),
                )
              else
                const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment row ───────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final String paymentMethod;
  final List<PaymentMethodInfo> availableMethods;
  final VoidCallback onTap;

  const _PaymentRow({
    required this.paymentMethod,
    required this.availableMethods,
    required this.onTap,
  });

  String get _label {
    if (paymentMethod == 'cash') return 'Cash';
    if (paymentMethod == 'wallet') return 'Wallet';
    try {
      return availableMethods.firstWhere((m) => m.id == paymentMethod).name;
    } catch (_) {
      return 'Online';
    }
  }

  IconData get _icon {
    if (paymentMethod == 'cash') return Icons.money;
    if (paymentMethod == 'wallet') return Icons.account_balance_wallet;
    return Icons.payment;
  }

  Color get _color {
    if (paymentMethod == 'cash') return Colors.green;
    if (paymentMethod == 'wallet') return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(_icon, size: 20, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down,
                  size: 20, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
