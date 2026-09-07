import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'flutter_plugin.dart';

/// Central registry for all Flutter plugins.
///
/// To add a new plugin:
///   1. Create your plugin folder at `lib/plugins/<name>/`
///   2. Implement [FlutterPlugin] in `lib/plugins/<name>/<name>_plugin.dart`
///   3. Add one line in `lib/plugins/plugin_manifest.dart`: `<SlugPlugin>()`
///
/// That's it. Routes, DI, and UI are all handled automatically.
class PluginRegistry {
  PluginRegistry._();
  static final PluginRegistry instance = PluginRegistry._();

  final List<FlutterPlugin> _plugins = [];

  /// Register all plugins. Called once before [configureDependencies].
  void registerPlugins(List<FlutterPlugin> plugins) {
    _plugins
      ..clear()
      ..addAll(plugins);
  }

  /// Register all plugin dependencies into GetIt.
  void registerAllDependencies(GetIt getIt) {
    for (final plugin in _plugins) {
      plugin.registerDependencies(getIt);
    }
  }

  /// All routes contributed by all plugins.
  List<RouteBase> get allRoutes {
    return _plugins.expand((p) => p.routes).toList();
  }

  bool _isSlugActive(FlutterPlugin plugin, Set<String> activePluginSlugs) {
    if (activePluginSlugs.isEmpty) return true; // If config list not loaded yet or empty, show available plugins
    final slug = plugin.slug;
    final hyphenated = slug.replaceAll('_', '-');
    return activePluginSlugs.contains(slug) ||
        activePluginSlugs.contains(hyphenated) ||
        activePluginSlugs.contains('inallcart-$slug') ||
        activePluginSlugs.contains('inallcart-$hyphenated');
  }

  /// All module buttons contributed by active plugins.
  /// [activePluginSlugs] comes from [PluginsConfig] — only show buttons
  /// for plugins the backend has activated.
  List<PluginModuleButton> getActiveModuleButtons(Set<String> activePluginSlugs) {
    return _plugins
        .where((p) => _isSlugActive(p, activePluginSlugs))
        .map((p) => p.moduleButton)
        .whereType<PluginModuleButton>()
        .toList();
  }

  /// All header tabs contributed by active plugins.
  List<PluginHeaderTab> getActiveHeaderTabs(Set<String> activePluginSlugs, [Map<String, String>? moduleIcons]) {
    return _plugins
        .where((p) => _isSlugActive(p, activePluginSlugs))
        .map((p) {
          final tab = p.headerTab;
          if (tab == null) return null;
          final dynamicIcon = moduleIcons?[p.slug] ?? moduleIcons?[p.slug.replaceAll('-', '_')] ?? tab.iconUrl;
          if (dynamicIcon != null && dynamicIcon.isNotEmpty) {
            return PluginHeaderTab(
              icon: tab.icon,
              label: tab.label,
              routePath: tab.routePath,
              iconUrl: dynamicIcon,
            );
          }
          return tab;
        })
        .whereType<PluginHeaderTab>()
        .toList();
  }

  /// Check if a specific plugin is registered.
  bool isRegistered(String slug) => _plugins.any((p) => p.slug == slug);

  List<FlutterPlugin> get all => List.unmodifiable(_plugins);
}
