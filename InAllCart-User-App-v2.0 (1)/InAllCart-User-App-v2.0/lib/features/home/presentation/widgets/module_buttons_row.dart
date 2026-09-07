import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/plugins/plugin_registry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';

/// Height of the module buttons row (including its bottom margin).
/// Used by [_calculateHeaderHeight] in [HomePage] to keep header sizing accurate.
const double kModuleButtonsRowHeight = 48.0;

/// Horizontal pill-button row rendered above the search bar on the home screen.
///
/// Each button represents a plugin-powered feature module (e.g. Ride Sharing).
/// A button is **only shown when its corresponding plugin is active** on the
/// backend — if no plugins are active the entire widget returns [SizedBox.shrink]
/// so no visual gap is created.
///
/// To add a new module button:
///   1. Create `lib/plugins/<slug>/<slug>_plugin.dart` implementing FlutterPlugin
///   2. Register it in `lib/plugins/plugin_manifest.dart`
///   Done. The button appears automatically when the backend activates the plugin.
class ModuleButtonsRow extends StatelessWidget {
  /// True when the home header has an image / video background.
  /// Controls whether buttons use a frosted-glass or primary-tinted style.
  final bool hasBackground;

  const ModuleButtonsRow({super.key, this.hasBackground = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      bloc: getIt<AppConfigBloc>(),
      buildWhen: (prev, curr) {
        // Only rebuild when plugin activation flags change
        if (prev is AppConfigLoaded && curr is AppConfigLoaded) {
          return prev.config.pluginsConfig != curr.config.pluginsConfig;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        if (state is! AppConfigLoaded) return const SizedBox.shrink();

        final plugins = state.config.pluginsConfig;

        // ─── Registry-driven module buttons ────────────────────────────────
        final activeButtons = PluginRegistry.instance
            .getActiveModuleButtons(plugins.activeSlugs);

        final buttons = <Widget>[
          for (final btn in activeButtons)
            _ModuleButton(
              icon: btn.icon,
              label: btn.label,
              hasBackground: hasBackground,
              onTap: () => context.push(btn.routePath),
            ),
        ];
        // ──────────────────────────────────────────────────────────────────

        if (buttons.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: buttons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => buttons[i],
            ),
          ),
        );
      },
    );
  }
}

/// A single pill-shaped shortcut button used inside [ModuleButtonsRow].
class _ModuleButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasBackground;
  final VoidCallback onTap;

  const _ModuleButton({
    required this.icon,
    required this.label,
    required this.hasBackground,
    required this.onTap,
  });

  @override
  State<_ModuleButton> createState() => _ModuleButtonState();
}

class _ModuleButtonState extends State<_ModuleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.hasBackground
        ? Colors.white.withValues(alpha: 0.22)
        : AppColors.primary.withValues(alpha: 0.10);

    final Color borderColor = widget.hasBackground
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.primary.withValues(alpha: 0.30);

    final Color contentColor =
        widget.hasBackground ? Colors.white : AppColors.primary;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: contentColor),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
