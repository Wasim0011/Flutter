import '../../domain/entities/app_config.dart';
import '../../../../core/constants/app_constants.dart';

class AppConfigModel extends AppConfig {
  const AppConfigModel({
    required super.onboardingEnabled,
    required super.onboardingScreens,
    required super.mapProvider,
    super.googleMapsApiKey,
    required super.pushNotificationConfig,
    required super.appName,
    required super.appVersion,
    super.supportEmail,
    super.supportPhone,
    required super.currencyConfig,
    required super.timezoneConfig,
    super.firebaseDatabaseUrl,
    super.maintenanceMode,
    super.maintenanceTitle,
    super.maintenanceMessage,
    super.maintenanceImageUrl,
    super.pluginsConfig,
    super.minAppVersion,
    super.latestAppVersion,
    super.forceUpdate,
    super.playStoreUrl,
    super.appStoreUrl,
    super.accountDeletionGracePeriod,
    super.showStarRating,
    super.showReviewCount,
    super.isDemoMode,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final onboardingScreens = (json['onboarding_screens'] as List?)
            ?.whereType<Map>()
            .map((e) => OnboardingScreenModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    onboardingScreens.sort((a, b) => a.order.compareTo(b.order));

    return AppConfigModel(
      onboardingEnabled: json['onboarding_enabled'] ?? true,
      onboardingScreens: onboardingScreens,
      mapProvider: json['map_provider'] == 'google'
          ? MapProvider.google
          : MapProvider.osm,
      googleMapsApiKey: json['google_maps_api_key'],
      pushNotificationConfig: PushNotificationConfigModel.fromJson(
        json['push_notification'] ?? {},
      ),
      appName: json['app_name'] ?? AppConstants.appName,
      appVersion: json['app_version'] ?? '1.0.0',
      supportEmail: json['support_email'],
      supportPhone: json['support_phone'],
      currencyConfig: CurrencyConfigModel.fromJson(
        json['currency'] ?? {},
      ),
      timezoneConfig: TimezoneConfigModel.fromJson(
        json['timezone'] ?? {},
      ),
      firebaseDatabaseUrl: json['firebase_database_url'],
      maintenanceMode: json['maintenance_mode'] ?? false,
      maintenanceTitle: json['maintenance_title'] ?? "We'll be back soon!",
      maintenanceMessage: json['maintenance_message'] ?? 'We are performing scheduled maintenance. Please check back shortly.',
      maintenanceImageUrl: json['maintenance_image_url'],
      pluginsConfig: PluginsConfigModel.fromJson(
        (json['plugins'] as Map<String, dynamic>?) ?? {},
      ),
      minAppVersion: json['min_app_version'] ?? json['app_update']?['min_version'] as String?,
      latestAppVersion: json['latest_app_version'] ?? json['app_update']?['latest_version'] as String?,
      forceUpdate: _parseBool(json['force_update'] ?? json['app_update']?['force_update'], defaultValue: false),
      playStoreUrl: json['play_store_url'] ?? json['app_update']?['play_store_url'] as String?,
      appStoreUrl: json['app_store_url'] ?? json['app_update']?['app_store_url'] as String?,
      showStarRating: _parseBool(json['show_star_rating'] ?? json['product_display']?['show_star_rating'], defaultValue: true),
      showReviewCount: _parseBool(json['show_review_count'] ?? json['product_display']?['show_review_count'], defaultValue: true),
      isDemoMode: _parseBool(json['is_demo_mode'] ?? json['demo_mode'], defaultValue: false),
    );
  }

  static bool _parseBool(dynamic val, {bool defaultValue = true}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is int) return val == 1;
    if (val is String) return val == '1' || val.toLowerCase() == 'true';
    return defaultValue;
  }

  Map<String, dynamic> toJson() => {
        'onboarding_enabled': onboardingEnabled,
        'onboarding_screens': onboardingScreens
            .map((e) => (e as OnboardingScreenModel).toJson())
            .toList(),
        'map_provider': mapProvider == MapProvider.google ? 'google' : 'osm',
        'google_maps_api_key': googleMapsApiKey,
        'push_notification':
            (pushNotificationConfig as PushNotificationConfigModel).toJson(),
        'app_name': appName,
        'app_version': appVersion,
        'support_email': supportEmail,
        'support_phone': supportPhone,
        'currency': (currencyConfig as CurrencyConfigModel).toJson(),
        'timezone': (timezoneConfig as TimezoneConfigModel).toJson(),
        'firebase_database_url': firebaseDatabaseUrl,
        'maintenance_mode': maintenanceMode,
        'maintenance_title': maintenanceTitle,
        'maintenance_message': maintenanceMessage,
        'maintenance_image_url': maintenanceImageUrl,
        'plugins': (pluginsConfig as PluginsConfigModel).toJson(),
        'auth': {
          'account_deletion_grace_period': accountDeletionGracePeriod,
        },
      };

  // Default config for when API is unavailable
  factory AppConfigModel.defaultConfig() => AppConfigModel(
        onboardingEnabled: true,
        onboardingScreens: const [
          OnboardingScreenModel(
            id: 1,
            title: 'Welcome!',
            subtitle: 'Your one-stop shop for everything you need',
            imageUrl: 'assets/images/onboarding_1.png',
            order: 1,
          ),
          OnboardingScreenModel(
            id: 2,
            title: 'Fast Delivery',
            subtitle: 'Get your orders delivered in minutes',
            imageUrl: 'assets/images/onboarding_2.png',
            order: 2,
          ),
          OnboardingScreenModel(
            id: 3,
            title: 'Easy Payments',
            subtitle: 'Multiple payment options for your convenience',
            imageUrl: 'assets/images/onboarding_3.png',
            order: 3,
          ),
        ],
        mapProvider: MapProvider.osm,
        pushNotificationConfig: const PushNotificationConfigModel(
          enabled: true,
          orderUpdates: true,
          promotions: true,
          newProducts: false,
        ),
        appName: AppConstants.appName,
        appVersion: '1.0.0',
        currencyConfig: const CurrencyConfigModel(
          defaultCurrency: 'INR',
          symbol: '₹',
          symbolPosition: 'left',
          decimalPlaces: 2,
          thousandSeparator: ',',
          multiCurrencyEnabled: false,
          supportedCurrencies: {},
        ),
        timezoneConfig: const TimezoneConfigModel(
          timezone: 'Asia/Kolkata',
          dateFormat: 'd/m/Y',
          timeFormat: '12',
        ),
      );
}

class OnboardingScreenModel extends OnboardingScreen {
  const OnboardingScreenModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.imageUrl,
    required super.order,
  });

  factory OnboardingScreenModel.fromJson(Map<String, dynamic> json) {
    return OnboardingScreenModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? json['image'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'order': order,
      };
}

class PushNotificationConfigModel extends PushNotificationConfig {
  const PushNotificationConfigModel({
    required super.enabled,
    required super.orderUpdates,
    required super.promotions,
    required super.newProducts,
  });

  factory PushNotificationConfigModel.fromJson(Map<String, dynamic> json) {
    return PushNotificationConfigModel(
      enabled: json['enabled'] ?? true,
      orderUpdates: json['order_updates'] ?? true,
      promotions: json['promotions'] ?? true,
      newProducts: json['new_products'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'order_updates': orderUpdates,
        'promotions': promotions,
        'new_products': newProducts,
      };
}

class CurrencyConfigModel extends CurrencyConfig {
  const CurrencyConfigModel({
    required super.defaultCurrency,
    required super.symbol,
    required super.symbolPosition,
    required super.decimalPlaces,
    required super.thousandSeparator,
    required super.multiCurrencyEnabled,
    required super.supportedCurrencies,
  });

  factory CurrencyConfigModel.fromJson(Map<String, dynamic> json) {
    final supportedCurrenciesMap = <String, CurrencyInfo>{};
    final supportedJson = json['supported_currencies'] as Map<String, dynamic>?;
    
    if (supportedJson != null) {
      supportedJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          supportedCurrenciesMap[key] = CurrencyInfoModel.fromJson(value);
        }
      });
    }

    return CurrencyConfigModel(
      defaultCurrency: json['active'] ?? json['default'] ?? 'INR',
      symbol: json['symbol'] ?? '₹',
      symbolPosition: json['symbol_position'] ?? 'left',
      decimalPlaces: json['decimal_places'] ?? 2,
      thousandSeparator: json['thousand_separator'] ?? ',',
      multiCurrencyEnabled: json['multi_currency_enabled'] ?? false,
      supportedCurrencies: supportedCurrenciesMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'default': defaultCurrency,
        'active': defaultCurrency, // preserve zone-resolved currency through cache round-trip
        'symbol': symbol,
        'symbol_position': symbolPosition,
        'decimal_places': decimalPlaces,
        'thousand_separator': thousandSeparator,
        'multi_currency_enabled': multiCurrencyEnabled,
        'supported_currencies': supportedCurrencies.map(
          (key, value) => MapEntry(key, (value as CurrencyInfoModel).toJson()),
        ),
      };
}

class CurrencyInfoModel extends CurrencyInfo {
  const CurrencyInfoModel({
    required super.name,
    required super.symbol,
  });

  factory CurrencyInfoModel.fromJson(Map<String, dynamic> json) {
    return CurrencyInfoModel(
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'symbol': symbol,
      };
}

class TimezoneConfigModel extends TimezoneConfig {
  const TimezoneConfigModel({
    required super.timezone,
    required super.dateFormat,
    required super.timeFormat,
  });

  factory TimezoneConfigModel.fromJson(Map<String, dynamic> json) {
    return TimezoneConfigModel(
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      dateFormat: json['date_format'] ?? 'd/m/Y',
      timeFormat: json['time_format'] ?? '12',
    );
  }

  Map<String, dynamic> toJson() => {
        'timezone': timezone,
        'date_format': dateFormat,
        'time_format': timeFormat,
      };
}

/// Model for the `plugins` block in the /api/v1/config/app response.
/// Dynamically maps any backend plugin slug to an active boolean flag.
/// Adding a new plugin requires no changes here — the backend just sends its slug.
class PluginsConfigModel extends PluginsConfig {
  const PluginsConfigModel({super.activeSlugs, super.moduleIcons});

  factory PluginsConfigModel.fromJson(Map<String, dynamic> json) {
    final slugs = <String>{};
    final icons = <String, String>{};

    json.forEach((key, value) {
      if (value == true) slugs.add(key);
      if (key == 'modules' && value is Map) {
        value.forEach((mKey, mVal) {
          if (mVal is Map) {
            if (mVal['is_active'] == true) {
              slugs.add(mKey.toString());
            }
            if (mVal['icon_url'] != null && mVal['icon_url'].toString().isNotEmpty) {
              icons[mKey.toString()] = mVal['icon_url'].toString();
            }
          }
        });
      }
    });

    return PluginsConfigModel(activeSlugs: slugs, moduleIcons: icons);
  }

  Map<String, dynamic> toJson() {
    return {for (final slug in activeSlugs) slug: true};
  }
}
