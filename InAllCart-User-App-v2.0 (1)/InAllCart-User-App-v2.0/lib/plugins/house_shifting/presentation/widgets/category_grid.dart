import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/item_category_model.dart';
import 'hs_icons.dart';

/// "What are you shifting?" category grid used in the booking flow.
/// No card background — just image/placeholder + name, with a selection
/// indicator ring when tapped.
class CategoryGrid extends StatelessWidget {
  final List<ItemCategoryModel> categories;
  final ItemCategoryModel? selected;
  final ValueChanged<ItemCategoryModel> onSelected;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you shifting?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: categories.length,
            itemBuilder: (_, i) => _CategoryChip(
              category: categories[i],
              isSelected: selected?.id == categories[i].id,
              onTap: () => onSelected(categories[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final ItemCategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  bool get _isUrl {
    final icon = widget.category.icon;
    if (icon == null || icon.isEmpty) return false;
    return icon.startsWith('http') || icon.startsWith('/storage');
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) { _scaleCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ListenableBuilder(
        listenable: _scaleAnim,
        builder: (context, _) => Transform.scale(
          scale: _scaleAnim.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image / placeholder — no card, just the image with optional
              // selection ring
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 2.5)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      isSelected ? 14 : 16), // inset by border width
                  child: _isUrl
                      ? Image.network(
                          widget.category.icon!,
                          width: double.infinity,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              SvgPicture.asset(HsIcons.placeholder,
                                  width: double.infinity, height: 70),
                        )
                      : SvgPicture.asset(HsIcons.placeholder,
                          width: double.infinity, height: 70),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
