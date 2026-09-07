/// Centralized SVG asset paths for the House Shifting plugin.
class HsIcons {
  HsIcons._();

  static const String _base = 'assets/icons';

  // Banner
  static const String banner = '$_base/hs_banner.svg';

  // Placeholder — shown when no image has been uploaded for an item
  static const String placeholder = '$_base/placeholder.svg';

  // Location
  static const String pickup = '$_base/hs_pickup.svg';
  static const String drop   = '$_base/hs_drop.svg';

  // UI
  static const String estimate = '$_base/hs_estimate.svg';
}
