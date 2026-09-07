import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import '../theme/ride_colors.dart';

/// The "Where to?" bottom sheet shown on the initial map screen.
///
/// Premium Uber/Rapido-style entry point: a greeting, a prominent search
/// pill, and a "Choose Vehicle" preview row (up to 6 vehicle types). Tapping
/// anything opens the location search screen.
class RideInitialSheet extends StatelessWidget {
  final String? pickupAddress;
  final String? destinationAddress;
  final List<VehicleType> vehicleTypes;
  final VoidCallback onSearchTap;

  const RideInitialSheet({
    super.key,
    this.pickupAddress,
    this.destinationAddress,
    this.vehicleTypes = const [],
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Where are you going?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // ── Prominent search pill ─────────────────────────────────
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: RideColors.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_rounded,
                        size: 20, color: RideColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destinationAddress ?? 'Search destination',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: destinationAddress == null
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: RideColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: RideColors.onAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Pickup hint row ───────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.my_location_rounded,
                  size: 16, color: RideColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup: ${pickupAddress ?? 'Current Location'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // ── Choose Vehicle preview ────────────────────────────────
          if (vehicleTypes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Choose Vehicle',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: vehicleTypes.length > 6 ? 6 : vehicleTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _VehiclePill(
                    vehicle: vehicleTypes[index],
                    onTap: onSearchTap,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehiclePill extends StatelessWidget {
  final VehicleType vehicle;
  final VoidCallback onTap;

  const _VehiclePill({required this.vehicle, required this.onTap});

  IconData _fallbackIcon() {
    final n = vehicle.name.toLowerCase();
    if (n.contains('bike') || n.contains('moto')) return Icons.two_wheeler;
    if (n.contains('auto')) return Icons.local_taxi;
    if (n.contains('xl') || n.contains('suv')) return Icons.airport_shuttle;
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    final hasIcon = vehicle.iconUrl != null && vehicle.iconUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              child: hasIcon
                  ? Image.network(
                      AppConstants.getFullMediaUrl(vehicle.iconUrl!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        _fallbackIcon(),
                        size: 34,
                        color: RideColors.primary,
                      ),
                    )
                  : Icon(_fallbackIcon(), size: 34, color: RideColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              vehicle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
