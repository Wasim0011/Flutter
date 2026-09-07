import 'package:equatable/equatable.dart';

class AppConfig extends Equatable {
  final bool onboardingEnabled;
  final List<OnboardingScreen> onboardingScreens;
  final MapProvider mapProvider;
  final String? googleMapsApiKey;
  final PushNotificationConfig pushNotificationConfig;
  final String appName;
  final String appVersion;
  final String? supportEmail;
  final String? supportPhone;
  final CurrencyConfig currencyConfig;
  final TimezoneConfig timezoneConfig;
  final String? firebaseDatabaseUrl;

  // Maintenance Mode
  final bool maintenanceMode;
  final String maintenanceTitle;
  final String maintenanceMessage;
  final String? maintenanceImageUrl;

  // Plugin activation flags (driven by backend plugin system)
  final PluginsConfig pluginsConfig;

  // In-App Update
  final String? minAppVersion;
  final String? latestAppVersion;
  final bool forceUpdate;
  final String? playStoreUrl;
  final String? appStoreUrl;

  // Demo Mode
  final bool isDemoMode;

  // Account Deletion
  final int accountDeletionGracePeriod;

  // Product Rating & Review Display Settings (Hot-reload safe)
  final bool? _showStarRating;
  final bool? _showReviewCount;

  bool get showStarRating => _showStarRating ?? true;
  bool get showReviewCount => _showReviewCount ?? true;

  const AppConfig({
    required this.onboardingEnabled,
    required this.onboardingScreens,
    required this.mapProvider,
    this.googleMapsApiKey,
    required this.pushNotificationConfig,
    required this.appName,
    required this.appVersion,
    this.supportEmail,
    this.supportPhone,
    required this.currencyConfig,
    required this.timezoneConfig,
    this.firebaseDatabaseUrl,
    this.maintenanceMode = false,
    this.maintenanceTitle = "We'll be back soon!",
    this.maintenanceMessage = 'We are performing scheduled maintenance. Please check back shortly.',
    this.maintenanceImageUrl,
    this.pluginsConfig = const PluginsConfig(),
    this.minAppVersion,
    this.latestAppVersion,
    this.forceUpdate = false,
    this.playStoreUrl,
    this.appStoreUrl,
    this.isDemoMode = false,
    this.accountDeletionGracePeriod = 7,
    bool? showStarRating = true,
    bool? showReviewCount = true,
  })  : _showStarRating = showStarRating,
        _showReviewCount = showReviewCount;

  @override
  List<Object?> get props => [
        onboardingEnabled,
        onboardingScreens,
        mapProvider,
        googleMapsApiKey,
        pushNotificationConfig,
        appName,
        appVersion,
        supportEmail,
        supportPhone,
        currencyConfig,
        timezoneConfig,
        firebaseDatabaseUrl,
        maintenanceMode,
        maintenanceTitle,
        maintenanceMessage,
        maintenanceImageUrl,
        pluginsConfig,
        accountDeletionGracePeriod,
      ];
}

/// Plugin activation status returned by the /config/app endpoint.
/// Uses a `Set<String>` of active slugs — no per-plugin field needed.
/// When a new plugin is added, only the backend needs to send its slug.
class PluginsConfig extends Equatable {
  /// Set of active plugin slugs from the backend.
  /// e.g. {'ride_sharing', 'food_ordering'}
  final Set<String> activeSlugs;

  /// Map of moduleKey -> uploaded icon URL from backend settings.
  final Map<String, String> moduleIcons;

  const PluginsConfig({
    this.activeSlugs = const {},
    this.moduleIcons = const {},
  });

  /// Convenience getter — kept for backward compatibility with existing code.
  bool get rideSharingActive => activeSlugs.contains('ride_sharing');

  /// Generic check for any plugin slug.
  bool isActive(String slug) => activeSlugs.contains(slug);

  /// Get uploaded module icon URL for a module
  String? getModuleIcon(String moduleKey) => moduleIcons[moduleKey];

  @override
  List<Object?> get props => [activeSlugs, moduleIcons];
}

class OnboardingScreen extends Equatable {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int order;

  const OnboardingScreen({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.order,
  });

  @override
  List<Object?> get props => [id, title, subtitle, imageUrl, order];
}

enum MapProvider { google, osm }

class PushNotificationConfig extends Equatable {
  final bool enabled;
  final bool orderUpdates;
  final bool promotions;
  final bool newProducts;

  const PushNotificationConfig({
    required this.enabled,
    required this.orderUpdates,
    required this.promotions,
    required this.newProducts,
  });

  @override
  List<Object?> get props => [enabled, orderUpdates, promotions, newProducts];
}

class CurrencyConfig extends Equatable {
  final String defaultCurrency;
  final String symbol;
  final String symbolPosition; // 'left' or 'right'
  final int decimalPlaces;
  final String thousandSeparator;
  final bool multiCurrencyEnabled;
  final Map<String, CurrencyInfo> supportedCurrencies;

  const CurrencyConfig({
    required this.defaultCurrency,
    required this.symbol,
    required this.symbolPosition,
    required this.decimalPlaces,
    required this.thousandSeparator,
    required this.multiCurrencyEnabled,
    required this.supportedCurrencies,
  });

  String formatAmount(double amount) {
    final decimalSeparator = thousandSeparator == ',' ? '.' : ',';
    
    String formatted = amount.toStringAsFixed(decimalPlaces);
    
    List<String> parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    String result = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = thousandSeparator + result;
      }
      result = integerPart[i] + result;
      count++;
    }
    
    if (decimalPlaces > 0 && decimalPart.isNotEmpty) {
      result += decimalSeparator + decimalPart;
    }
    
    if (symbolPosition == 'left') {
      return '$symbol$result';
    } else {
      return '$result$symbol';
    }
  }

  @override
  List<Object?> get props => [
        defaultCurrency,
        symbol,
        symbolPosition,
        decimalPlaces,
        thousandSeparator,
        multiCurrencyEnabled,
        supportedCurrencies,
      ];
}

class CurrencyInfo extends Equatable {
  final String name;
  final String symbol;

  const CurrencyInfo({
    required this.name,
    required this.symbol,
  });

  @override
  List<Object?> get props => [name, symbol];
}

class TimezoneConfig extends Equatable {
  final String timezone;
  final String dateFormat;
  final String timeFormat; // '12' or '24'

  const TimezoneConfig({
    required this.timezone,
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  List<Object?> get props => [timezone, dateFormat, timeFormat];
}
