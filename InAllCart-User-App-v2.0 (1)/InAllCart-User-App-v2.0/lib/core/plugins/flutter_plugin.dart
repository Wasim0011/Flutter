import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The contract every Flutter plugin must implement.
/// A plugin is self-contained — it registers its own DI, routes, and UI.
abstract class FlutterPlugin {
  /// Unique slug matching the backend plugin slug (e.g. 'ride_sharing').
  /// Must match the key in the backend `plugins` config response.
  String get slug;

  /// Human-readable name shown in logs and debug tools.
  String get name;

  /// Register all GetIt dependencies for this plugin.
  /// Called once during app startup via [PluginRegistry.registerAll].
  void registerDependencies(GetIt getIt);

  /// GoRouter routes this plugin contributes to the app.
  /// Called when building the router.
  List<RouteBase> get routes;

  /// Optional: A pill button to show in the home screen module row.
  /// Return null if this plugin doesn't need a home screen shortcut.
  PluginModuleButton? get moduleButton;

  /// Optional: A tab entry to show in the home header tabs row
  /// alongside category tabs. Return null if this plugin doesn't
  /// need a tab in the header.
  PluginHeaderTab? get headerTab;
}

/// Describes a pill-shaped shortcut button for the home screen module row.
class PluginModuleButton {
  final IconData icon;
  final String label;
  final String routePath; // GoRouter path to push
  final String? iconUrl;

  const PluginModuleButton({
    required this.icon,
    required this.label,
    required this.routePath,
    this.iconUrl,
  });
}

/// Describes a tab entry in the home header tabs row.
class PluginHeaderTab {
  final IconData icon;
  final String label;
  final String routePath;
  final String? iconUrl;

  const PluginHeaderTab({
    required this.icon,
    required this.label,
    required this.routePath,
    this.iconUrl,
  });
}
