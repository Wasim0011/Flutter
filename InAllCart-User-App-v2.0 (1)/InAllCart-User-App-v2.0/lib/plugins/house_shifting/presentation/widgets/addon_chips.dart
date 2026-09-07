import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../data/models/addon_service_model.dart';
import 'hs_icons.dart';

/// Add-on service selection chips with SVG icons, system currency,
/// and scale-bounce micro-animation.
class AddonChips extends StatelessWidget {
  final List<AddonServiceModel> addons;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  const AddonChips({
    super.key,
    required this.addons,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add-on Services',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enhance your shifting experience',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 12),
          BlocBuilder<AppConfigBloc, AppConfigState>(
            builder: (context, configState) {
              final currencyConfig = configState is AppConfigLoaded
                  ? configState.config.currencyConfig
                  : null;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: addons.map((addon) {
                  final isOn = selectedIds.contains(addon.id);
                  return _AddonChip(
                    addon: addon,
                    isSelected: isOn,
                    onTap: () => onToggle(addon.id),
                    currencyConfig: currencyConfig,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddonChip extends StatefulWidget {
  final AddonServiceModel addon;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic currencyConfig;

  const _AddonChip({
    required this.addon,
    required this.isSelected,
    required this.onTap,
    required this.currencyConfig,
  });

  @override
  State<_AddonChip> createState() => _AddonChipState();
}

class _AddonChipState extends State<_AddonChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.9,
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
    final priceText = CurrencyFormatter.formatAmount(
      widget.addon.price,
      widget.currencyConfig,
    );

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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: _AddonIcon(addon: widget.addon, isSelected: isSelected),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.addon.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priceText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Renders an addon icon: network image if `icon` is a URL, else placeholder.svg.
class _AddonIcon extends StatelessWidget {
  final AddonServiceModel addon;
  final bool isSelected;

  const _AddonIcon({required this.addon, required this.isSelected});

  bool get _isUrl {
    final icon = addon.icon;
    if (icon == null || icon.isEmpty) return false;
    return icon.startsWith('http') || icon.startsWith('/storage');
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    if (_isUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          addon.icon!,
          width: 15,
          height: 15,
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
