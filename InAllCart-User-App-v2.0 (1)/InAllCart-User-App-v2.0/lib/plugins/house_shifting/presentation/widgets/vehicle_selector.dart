import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../data/models/service_type_model.dart';
import 'hs_icons.dart';

/// Vehicle selection list with premium cards, SVG icons, pricing
/// from system currency, and scale-bounce micro-animation on tap.
class VehicleSelector extends StatelessWidget {
  final List<ServiceTypeModel> vehicles;
  final ServiceTypeModel? selected;
  final ValueChanged<ServiceTypeModel> onSelected;

  const VehicleSelector({
    super.key,
    required this.vehicles,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Vehicle',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...vehicles.map(
            (v) => _VehicleCard(
              vehicle: v,
              isSelected: selected?.id == v.id,
              onTap: () => onSelected(v),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatefulWidget {
  final ServiceTypeModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencyConfig = configState is AppConfigLoaded
            ? configState.config.currencyConfig
            : null;

        final baseFeeText = CurrencyFormatter.formatAmount(
          widget.vehicle.baseFee,
          currencyConfig,
        );
        final perKmText =
            '+${CurrencyFormatter.formatAmount(widget.vehicle.perKmRate, currencyConfig)}/km';

        return GestureDetector(
          onTapDown: (_) => _scaleCtrl.forward(),
          onTapUp: (_) {
            _scaleCtrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _scaleCtrl.reverse(),
          child: ListenableBuilder(
            listenable: _scaleAnim,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Vehicle icon container — solid color, no gradient
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: _VehicleIcon(
                          vehicle: widget.vehicle,
                          isSelected: isSelected,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name + capacity
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vehicle.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.vehicle.capacityDisplay,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (widget.vehicle.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.vehicle.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Pricing — uses system currency
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            baseFeeText,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              perKmText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Renders a vehicle icon: network image if `icon` is a URL, else placeholder.svg.
class _VehicleIcon extends StatelessWidget {
  final ServiceTypeModel vehicle;
  final bool isSelected;

  const _VehicleIcon({required this.vehicle, required this.isSelected});

  bool get _isUrl {
    final icon = vehicle.icon;
    if (icon == null || icon.isEmpty) return false;
    return icon.startsWith('http') || icon.startsWith('/storage');
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : AppColors.textSecondary;

    if (_isUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          vehicle.icon!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _svgFallback(color),
        ),
      );
    }
    return _svgFallback(color);
  }

  Widget _svgFallback(Color color) {
    return SvgPicture.asset(HsIcons.placeholder);
  }
}
