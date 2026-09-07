import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Handles all local persistence.
///
/// Sensitive credentials (auth tokens, refresh tokens) are stored in
/// [FlutterSecureStorage] (Keychain on iOS, EncryptedSharedPreferences /
/// Android Keystore on Android).
///
/// Non-sensitive preferences (theme, language, onboarding flag, etc.) remain
/// in [SharedPreferences] for performance.
class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  StorageService(this._prefs)
      : _secure = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // ============== TOKEN (secure) ==============
  Future<void> setToken(String token) async {
    await _secure.write(key: AppConstants.tokenKey, value: token);
    // Keep a non-sensitive presence flag in prefs for synchronous isLoggedIn checks.
    // The actual token value is only in secure storage.
    await _prefs.setBool('_has_token', true);
  }

  Future<String?> getTokenAsync() =>
      _secure.read(key: AppConstants.tokenKey);

  /// Synchronous-style getter — reads from secure storage cache.
  /// Returns null until [setToken] has been called at least once.
  /// Prefer [getTokenAsync] where async is possible.
  String? getToken() => _prefs.getBool('_has_token') == true ? '__cached__' : null;

  Future<void> setRefreshToken(String token) =>
      _secure.write(key: AppConstants.refreshTokenKey, value: token);

  Future<String?> getRefreshTokenAsync() =>
      _secure.read(key: AppConstants.refreshTokenKey);

  // ============== USER (secure) ==============
  Future<void> setUser(Map<String, dynamic> user) async {
    await _secure.write(key: AppConstants.userKey, value: jsonEncode(user));
    // Cache a non-sensitive copy in prefs for synchronous reads.
    await _prefs.setString('_user_cache', jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserAsync() async {
    final data = await _secure.read(key: AppConstants.userKey);
    return data != null ? jsonDecode(data) as Map<String, dynamic> : null;
  }

  /// Synchronous getter backed by a prefs cache written on [setUser].
  Map<String, dynamic>? getUser() {
    final data = _prefs.getString('_user_cache');
    return data != null ? jsonDecode(data) as Map<String, dynamic> : null;
  }

  // ============== DEVICE ==============
  Future<void> setDeviceId(String id) =>
      _prefs.setString(AppConstants.deviceIdKey, id);
  String? getDeviceId() => _prefs.getString(AppConstants.deviceIdKey);

  // ============== ONBOARDING ==============
  Future<void> setOnboardingCompleted(bool completed) =>
      _prefs.setBool(AppConstants.onboardingCompletedKey, completed);
  bool isOnboardingCompleted() =>
      _prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

  // ============== APP CONFIG ==============
  Future<void> setAppConfig(Map<String, dynamic> config) =>
      _prefs.setString(AppConstants.appConfigKey, jsonEncode(config));

  Map<String, dynamic>? getAppConfig() {
    final data = _prefs.getString(AppConstants.appConfigKey);
    return data != null ? jsonDecode(data) as Map<String, dynamic> : null;
  }

  // ============== FCM TOKEN (secure) ==============
  Future<void> setFcmToken(String token) =>
      _secure.write(key: AppConstants.fcmTokenKey, value: token);

  Future<void> removeFcmToken() =>
      _secure.delete(key: AppConstants.fcmTokenKey);

  Future<String?> getFcmToken() =>
      _secure.read(key: AppConstants.fcmTokenKey);

  // ============== THEME ==============
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(AppConstants.themeKey, mode);
  String? getThemeMode() => _prefs.getString(AppConstants.themeKey);

  // ============== LANGUAGE ==============
  Future<void> setLanguage(String language) =>
      _prefs.setString(AppConstants.languageKey, language);
  String? getLanguage() => _prefs.getString(AppConstants.languageKey);

  // ============== CART (OFFLINE) ==============
  Future<void> setCart(Map<String, dynamic> cart) =>
      _prefs.setString(AppConstants.cartKey, jsonEncode(cart));

  Map<String, dynamic>? getCart() {
    final data = _prefs.getString(AppConstants.cartKey);
    return data != null ? jsonDecode(data) as Map<String, dynamic> : null;
  }

  Future<void> clearCart() => _prefs.remove(AppConstants.cartKey);

  // ============== LAST PAYMENT METHOD ==============
  Future<void> setLastPaymentMethodId(String id) =>
      _prefs.setString('last_payment_method_id', id);
  String? getLastPaymentMethodId() =>
      _prefs.getString('last_payment_method_id');

  // ============== CLEAR ==============
  Future<void> clearAuth() async {
    await _secure.delete(key: AppConstants.tokenKey);
    await _secure.delete(key: AppConstants.refreshTokenKey);
    await _secure.delete(key: AppConstants.userKey);
    // Clear synchronous cache keys
    await _prefs.remove('_has_token');
    await _prefs.remove('_user_cache');
    await clearDefaultAddressLabel();
    await clearLocation();
  }

  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }

  // ============== HELPERS ==============
  /// Async login check — reads from secure storage.
  Future<bool> get isLoggedInAsync async {
    final token = await _secure.read(key: AppConstants.tokenKey);
    return token != null;
  }

  /// Synchronous login check backed by a prefs flag written on [setToken].
  /// Use [isLoggedInAsync] when async is acceptable.
  bool get isLoggedIn => _prefs.getBool('_has_token') == true;

  // ============== LOCATION ==============
  Future<void> setLocation(double lat, double lng, {String? label}) async {
    await _prefs.setDouble(AppConstants.latitudeKey, lat);
    await _prefs.setDouble(AppConstants.longitudeKey, lng);
    if (label != null) {
      await _prefs.setString(AppConstants.cachedAddressLabelKey, label);
    }
  }

  Map<String, double>? getLocation() {
    final lat = _prefs.getDouble(AppConstants.latitudeKey);
    final lng = _prefs.getDouble(AppConstants.longitudeKey);
    if (lat != null && lng != null) {
      return {'lat': lat, 'lng': lng};
    }
    return null;
  }

  String? getCachedAddressLabel() =>
      _prefs.getString(AppConstants.cachedAddressLabelKey);

  String? getDefaultAddressLabel() =>
      _prefs.getString('default_address_label');

  Future<void> setDefaultAddressLabel(String label) =>
      _prefs.setString('default_address_label', label);

  Future<void> clearDefaultAddressLabel() =>
      _prefs.remove('default_address_label');

  Future<void> clearLocation() async {
    await _prefs.remove(AppConstants.latitudeKey);
    await _prefs.remove(AppConstants.longitudeKey);
    await _prefs.remove(AppConstants.cachedAddressLabelKey);
  }

  // ============== NOTIFICATIONS (local store) ==============
  static const _notificationsKey = 'local_notifications';
  static const _maxNotifications = 50;

  /// Save an incoming notification. Keeps newest [_maxNotifications] entries.
  Future<void> saveNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final list = getNotifications();
    list.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'data': data ?? {},
      'isRead': false,
      'receivedAt': DateTime.now().toIso8601String(),
    });
    final trimmed = list.take(_maxNotifications).toList();
    await _prefs.setString(_notificationsKey, jsonEncode(trimmed));
  }

  List<Map<String, dynamic>> getNotifications() {
    final raw = _prefs.getString(_notificationsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  int getUnreadNotificationCount() =>
      getNotifications().where((n) => n['isRead'] == false).length;

  Future<void> markAllNotificationsRead() async {
    final list =
        getNotifications().map((n) => {...n, 'isRead': true}).toList();
    await _prefs.setString(_notificationsKey, jsonEncode(list));
  }

  Future<void> saveRawNotifications(List<Map<String, dynamic>> list) =>
      _prefs.setString(_notificationsKey, jsonEncode(list));

  Future<void> clearNotifications() => _prefs.remove(_notificationsKey);

  // ============== SPLASH CONFIG CACHE ==============
  Future<void> setSplashConfig(Map<String, dynamic> config) =>
      _prefs.setString('_splash_config_cache', jsonEncode(config));

  Map<String, dynamic>? getSplashConfig() {
    final raw = _prefs.getString('_splash_config_cache');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ============== POPUP & APP OPEN TRACKING ==============
  static final Set<int> _sessionSeenPopups = {};

  Future<int> incrementAppOpenCount() async {
    final current = getAppOpenCount() + 1;
    await _prefs.setInt('_app_open_count', current);
    return current;
  }

  int getAppOpenCount() => _prefs.getInt('_app_open_count') ?? 0;

  Future<void> markPopupSeenUser(int popupId) async {
    final seenList = getSeenPopupIdsUser();
    if (!seenList.contains(popupId)) {
      seenList.add(popupId);
      await _prefs.setStringList('_seen_popup_ids_user', seenList.map((e) => e.toString()).toList());
    }
  }

  List<int> getSeenPopupIdsUser() {
    final raw = _prefs.getStringList('_seen_popup_ids_user') ?? [];
    return raw.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  Future<void> markPopupShownToday(int popupId) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.setString('_popup_today_$popupId', todayStr);
  }

  bool wasPopupShownToday(int popupId) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final saved = _prefs.getString('_popup_today_$popupId');
    return saved == todayStr;
  }

  void markPopupShownSession(int popupId) {
    _sessionSeenPopups.add(popupId);
  }

  bool wasPopupShownSession(int popupId) {
    return _sessionSeenPopups.contains(popupId);
  }

  // ============== SEARCH HISTORY ==============
  static const int _maxSearchHistory = 10;

  List<String> getSearchHistory() {
    return _prefs.getStringList(AppConstants.searchHistoryKey) ?? [];
  }

  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final history = getSearchHistory();
    // Remove if already exists to move to top
    history.remove(query);
    history.insert(0, query);
    
    final trimmed = history.take(_maxSearchHistory).toList();
    await _prefs.setStringList(AppConstants.searchHistoryKey, trimmed);
  }

  Future<void> removeFromSearchHistory(String query) async {
    final history = getSearchHistory();
    if (history.remove(query)) {
      await _prefs.setStringList(AppConstants.searchHistoryKey, history);
    }
  }

  Future<void> clearSearchHistory() =>
      _prefs.remove(AppConstants.searchHistoryKey);

  // ============== AI HISTORY ==============
  List<String> getAiHistory() {
    return _prefs.getStringList(AppConstants.aiHistoryKey) ?? [];
  }

  Future<void> addToAiHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final history = getAiHistory();
    history.remove(query);
    history.insert(0, query);
    
    final trimmed = history.take(10).toList();
    await _prefs.setStringList(AppConstants.aiHistoryKey, trimmed);
  }

  Future<void> removeFromAiHistory(String query) async {
    final history = getAiHistory();
    if (history.remove(query)) {
      await _prefs.setStringList(AppConstants.aiHistoryKey, history);
    }
  }

  Future<void> clearAiHistory() =>
      _prefs.remove(AppConstants.aiHistoryKey);
}
