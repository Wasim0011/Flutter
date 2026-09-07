import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/app_config/domain/entities/app_config.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import '../theme/ride_colors.dart';

/// Bottom sheet shown after a driver is assigned.
/// Displays status, OTP pin, driver card, vehicle info,
/// and action buttons (Call, Safety/SOS, Share).
class RideDriverAssignedSheet extends StatelessWidget {
  final Ride ride;
  final CurrencyConfig currency;
  final VoidCallback onCallDriver;
  final VoidCallback onSOS;
  final VoidCallback onShareTrip;

  const RideDriverAssignedSheet({
    super.key,
    required this.ride,
    required this.currency,
    required this.onCallDriver,
    required this.onSOS,
    required this.onShareTrip,
  });

  _StatusConfig get _status {
    switch (ride.status) {
      case 'arriving':
        return _StatusConfig(
          label: 'Captain is on the way',
          sub: 'Head to your pickup point',
          color: Colors.orange,
          showPin: true,
        );
      case 'arrived':
        return _StatusConfig(
          label: 'Captain has arrived!',
          sub: 'Meet your captain at the pickup',
          color: Colors.green,
          showPin: true,
        );
      case 'started':
        return _StatusConfig(
          label: 'On the way to destination',
          sub: 'Sit back and enjoy the ride',
          color: Colors.blue,
          showPin: false,
        );
      default:
        return _StatusConfig(
          label: 'Captain assigned',
          sub: 'Head to your pickup point',
          color: Colors.green,
          showPin: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ride.driver;
    final cfg = _status;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status header + OTP ───────────────────────────────────
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: cfg.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cfg.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: cfg.color,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      cfg.sub,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (cfg.showPin && ride.ridePin != null)
                _OtpBadge(pin: ride.ridePin!),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // ── Driver card ───────────────────────────────────────────
          if (driver != null)
            _DriverCard(
              driver: driver,
              vehicleTypeName: ride.vehicleTypeName,
              totalFare: ride.totalFare,
              currency: currency,
            ),

          const SizedBox(height: 14),

          // ── Action buttons ────────────────────────────────────────
          Row(
            children: [
              _ActionButton(
                icon: Icons.call_outlined,
                label: 'Call',
                color: Colors.black87,
                bgColor: const Color(0xFFF0F0F0),
                onTap: onCallDriver,
              ),
              const SizedBox(width: 10),
              _ActionButton(
                icon: Icons.shield_outlined,
                label: 'Safety',
                color: Colors.red,
                bgColor: Colors.red.withOpacity(0.08),
                onTap: onSOS,
              ),
              const SizedBox(width: 10),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.black87,
                bgColor: const Color(0xFFF0F0F0),
                onTap: onShareTrip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── OTP badge ─────────────────────────────────────────────────────────

class _OtpBadge extends StatelessWidget {
  final String pin;
  const _OtpBadge({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: RideColors.darkGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PIN',
            style: TextStyle(
              fontSize: 9,
              color: RideColors.accent.withOpacity(0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          Text(
            pin,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: RideColors.accent,
              letterSpacing: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Driver card ───────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final RideDriver driver;
  final String? vehicleTypeName;
  final double totalFare;
  final CurrencyConfig currency;

  const _DriverCard({
    required this.driver,
    this.vehicleTypeName,
    required this.totalFare,
    required this.currency,
  });

  IconData _vehicleIcon() {
    final n = (vehicleTypeName ?? '').toLowerCase();
    if (n.contains('bike') || n.contains('moto')) return Icons.two_wheeler;
    if (n.contains('auto')) return Icons.local_taxi;
    if (n.contains('xl') || n.contains('suv')) return Icons.airport_shuttle;
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Driver info row
        Row(
          children: [
            // Photo
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEEEEEE),
              ),
              clipBehavior: Clip.antiAlias,
              child: driver.photo != null && driver.photo!.isNotEmpty
                  ? Image.network(
                      AppConstants.getFullMediaUrl(driver.photo!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 34,
                          color: Colors.grey),
                    )
                  : const Icon(Icons.person, size: 34, color: Colors.grey),
            ),
            const SizedBox(width: 14),

            // Name + rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        driver.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Call button
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_outlined,
                    size: 20, color: Colors.black87),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Vehicle info row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Icon(_vehicleIcon(), size: 20, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${driver.vehicleColor ?? ''} ${driver.vehicleMake ?? ''} ${driver.vehicleModel ?? ''}'
                          .trim(),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (driver.vehiclePlateNumber != null)
                      Text(
                        driver.vehiclePlateNumber!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                currency.formatAmount(totalFare),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusConfig {
  final String label;
  final String sub;
  final Color color;
  final bool showPin;

  const _StatusConfig({
    required this.label,
    required this.sub,
    required this.color,
    required this.showPin,
  });
}
