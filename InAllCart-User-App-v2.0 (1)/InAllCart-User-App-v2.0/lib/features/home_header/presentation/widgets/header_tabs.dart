import 'package:go_router/go_router.dart';
import '../../../../core/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/plugins/flutter_plugin.dart';
import '../../domain/entities/home_header_config.dart';

/// Category filter tabs shown below search bar (Blinkit style)
/// Square image box + name below + active indicator bar
///
/// Plugin tabs (Ride, Food, etc.) are appended automatically from
/// [pluginTabs] — no hardcoded per-plugin logic needed.
class HeaderTabs extends StatefulWidget {
  final List<HomeHeaderTab> tabs;
  final int selectedTabId;
  final ValueChanged<int> onTabSelected;
  final bool isCompact;
  final bool isHorizontalStyle;
  final String moduleIconStyle; // 'image_only' or 'image_and_name'

  /// Plugin-contributed tabs from [PluginRegistry.getActiveHeaderTabs].
  /// Each one renders as an icon+label tab at the end of the category list.
  final List<PluginHeaderTab> pluginTabs;

  const HeaderTabs({
    super.key,
    required this.tabs,
    required this.selectedTabId,
    required this.onTabSelected,
    this.isCompact = false,
    this.isHorizontalStyle = false,
    this.moduleIconStyle = 'image_and_name',
    this.pluginTabs = const [],
  });

  @override
  State<HeaderTabs> createState() => _HeaderTabsState();
}

class _HeaderTabsState extends State<HeaderTabs> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.tabs.isEmpty) return const SizedBox.shrink();

    // Check if horizontal layout (Zepto style) should be used
    final isImageOnly = widget.moduleIconStyle == 'image_only';

    if (widget.isHorizontalStyle) {
      return Container(
        height: widget.isCompact ? (isImageOnly ? 58 : 74) : (isImageOnly ? 70 : 86),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.tabs.length + widget.pluginTabs.length,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            if (index < widget.tabs.length) {
              final tab = widget.tabs[index];
              final isSelected = tab.id == widget.selectedTabId;
              return _buildHorizontalCategoryTab(context, tab, isSelected);
            } else {
              final pluginIndex = index - widget.tabs.length;
              final pluginTab = widget.pluginTabs[pluginIndex];
              return _buildPluginTab(context, pluginTab);
            }
          },
        ),
      );
    }

    // Default Vertical Image + Text / Image Only style layout
    return Container(
      height: widget.isCompact ? (isImageOnly ? 58 : 84) : (isImageOnly ? 60 : 86),
      padding: EdgeInsets.symmetric(vertical: widget.isCompact ? 2 : 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length + widget.pluginTabs.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          if (index < widget.tabs.length) {
            final tab = widget.tabs[index];
            final isSelected = tab.id == widget.selectedTabId;
            return _buildVerticalCategoryTab(tab, isSelected);
          } else {
            final pluginIndex = index - widget.tabs.length;
            final pluginTab = widget.pluginTabs[pluginIndex];
            return _buildPluginTab(context, pluginTab);
          }
        },
      ),
    );
  }

  // ─── Horizontal style category tab ─────────────────────────────────────

  Widget _buildHorizontalCategoryTab(BuildContext context, HomeHeaderTab tab, bool isSelected) {
    final isImageOnly = widget.moduleIconStyle == 'image_only';
    final squareSize = widget.isCompact ? (isImageOnly ? 48.0 : 44.0) : (isImageOnly ? 58.0 : 54.0);
    final fontSize = widget.isCompact ? 9.5 : 11.0;

    return GestureDetector(
      onTap: () => widget.onTabSelected(tab.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2.0)
                    : Border.all(color: const Color(0x0F000000), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: tab.categoryImage != null && tab.categoryImage!.isNotEmpty
                    ? CachedImage(
                        imageUrl: tab.categoryImage!,
                        width: squareSize,
                        height: squareSize,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                      )
                    : Container(color: AppColors.surfaceLight),
              ),
            ),
            if (!isImageOnly) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: squareSize + 14,
                child: Text(
                  tab.displayName,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: fontSize,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Vertical style category tab ───────────────────────────────────────

  Widget _buildVerticalCategoryTab(HomeHeaderTab tab, bool isSelected) {
    final isImageOnly = widget.moduleIconStyle == 'image_only';
    final squareSize = widget.isCompact ? (isImageOnly ? 48.0 : 44.0) : (isImageOnly ? 58.0 : 54.0);
    final fontSize = widget.isCompact ? 9.5 : 11.0;
    final itemWidth = widget.isCompact ? (isImageOnly ? 58.0 : 62.0) : (isImageOnly ? 70.0 : 74.0);

    return GestureDetector(
      onTap: () => widget.onTabSelected(tab.id),
      child: Container(
        width: itemWidth,
        alignment: Alignment.topCenter,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2.0)
                    : Border.all(color: const Color(0x0F000000), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCategoryImage(tab, squareSize),
              ),
            ),
            if (!isImageOnly) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  tab.displayName,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: fontSize,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? (widget.isCompact ? 16 : 20) : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ─── Plugin tab (generic — works for any plugin) ───────────────────────

  Widget _buildPluginTab(BuildContext context, PluginHeaderTab pluginTab) {
    final isImageOnly = widget.moduleIconStyle == 'image_only';
    final squareSize = widget.isCompact ? (isImageOnly ? 48.0 : 44.0) : (isImageOnly ? 58.0 : 54.0);
    final fontSize = widget.isCompact ? 9.5 : 11.0;
    final itemWidth = widget.isCompact ? (isImageOnly ? 58.0 : 62.0) : (isImageOnly ? 70.0 : 74.0);

    return GestureDetector(
      onTap: () => context.push(pluginTab.routePath),
      child: Container(
        width: itemWidth,
        alignment: Alignment.topCenter,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x0F000000), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: pluginTab.iconUrl != null && pluginTab.iconUrl!.isNotEmpty
                    ? CachedImage(
                        imageUrl: pluginTab.iconUrl!,
                        width: squareSize,
                        height: squareSize,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: AppColors.surfaceLight,
                          child: Icon(pluginTab.icon, color: AppColors.primary, size: squareSize * 0.5),
                        ),
                      )
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(pluginTab.icon, color: AppColors.primary, size: squareSize * 0.5),
                      ),
              ),
            ),
            if (!isImageOnly) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  pluginTab.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Container(width: widget.isCompact ? 16 : 20, height: 2.5, color: Colors.transparent),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(HomeHeaderTab tab, double size) {
    if (tab.categoryImage != null && tab.categoryImage!.isNotEmpty) {
      return CachedImage(
        imageUrl: tab.categoryImage!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: Container(
          color: AppColors.surfaceLight,
          child: Icon(
            Icons.category_outlined,
            size: size * 0.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Fallback icon if no image
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        Icons.category_outlined,
        size: size * 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}
