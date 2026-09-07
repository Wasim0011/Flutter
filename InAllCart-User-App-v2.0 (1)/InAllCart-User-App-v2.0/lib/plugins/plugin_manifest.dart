/// Plugin manifest — the ONLY place you register new plugins.
///
/// Import your plugin class and add it to the list below.
/// The main app (main.dart, injection.dart, app_router.dart) reads from
/// [PluginRegistry] — they never need to be edited for new plugins.
///
/// HOW TO ADD A NEW PLUGIN:
///   1. Create `lib/plugins/<slug>/<slug>_plugin.dart` implementing FlutterPlugin
///   2. Add: `import '<slug>/<slug>_plugin.dart';`
///   3. Add: `<SlugPlugin>()` to the list below
///   Done. Routes, DI, and home button are all wired automatically.
library;

import '../core/plugins/plugin_registry.dart';
import 'house_shifting/house_shifting_plugin.dart';
import 'ride_sharing/ride_sharing_plugin.dart';

void registerAllPlugins() {
  PluginRegistry.instance.registerPlugins([
    HouseShiftingPlugin(),
    RideSharingPlugin(),
    // Add new plugins here ↓
  ]);
}
