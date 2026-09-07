import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import 'hs_icons.dart';

/// Pickup/Drop location card with visual timeline connector.
/// Address input with SVG icons.
class LocationCard extends StatelessWidget {
  final VoidCallback? onPickupTap;
  final VoidCallback? onDropTap;
  final String? pickupAddress;
  final String? dropAddress;
  final int pickupFloor;
  final bool pickupLift;
  final int dropFloor;
  final bool dropLift;

  const LocationCard({
    super.key,
    this.onPickupTap,
    this.onDropTap,
    this.pickupAddress,
    this.dropAddress,
    this.pickupFloor = 0,
    this.pickupLift = false,
    this.dropFloor = 0,
    this.dropLift = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow(
            svgPath: HsIcons.pickup,
            iconColor: AppColors.secondary,
            label: 'PICKUP',
            text: pickupAddress,
            hint: 'Enter pickup address',
            onTap: onPickupTap,
            isTop: true,
            floor: pickupFloor,
            lift: pickupLift,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 27),
            child: Row(
              children: [
                Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 2,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Divider(height: 1, color: AppColors.border),
                ),
              ],
            ),
          ),
          _buildRow(
            svgPath: HsIcons.drop,
            iconColor: AppColors.error,
            label: 'DROP',
            text: dropAddress,
            hint: 'Enter drop address',
            onTap: onDropTap,
            isTop: false,
            floor: dropFloor,
            lift: dropLift,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String svgPath,
    required Color iconColor,
    required String label,
    required String hint,
    String? text,
    required bool isTop,
    VoidCallback? onTap,
    int? floor,
    bool? lift,
  }) {
    final hasText = text != null && text.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(16) : Radius.zero,
        bottom: isTop ? Radius.zero : const Radius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: SvgPicture.asset(
                svgPath,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasText ? text : hint,
                    style: TextStyle(
                      color: hasText ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: hasText ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasText)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Floor: ${floor == 0 ? "Ground" : floor}  •  Lift: ${lift == true ? "Yes" : "No"}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">'
              '<path d="M9 6l6 6-6 6" stroke="currentColor" stroke-width="2" '
              'stroke-linecap="round" stroke-linejoin="round" opacity="0.5"/></svg>',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.textTertiary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
