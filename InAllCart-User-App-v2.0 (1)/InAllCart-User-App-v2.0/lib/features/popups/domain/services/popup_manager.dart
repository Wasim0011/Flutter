import 'dart:async';

import '../../../../core/services/storage_service.dart';
import '../../data/datasources/popup_remote_datasource.dart';
import '../../data/models/popup_model.dart';
import '../entities/popup.dart';

enum PopupContextTrigger {
  onAppOpen,
  onLogin,
  onOrderCompletion,
  onBeforeCheckout,
  onCartChange,
  onAppExit,
}

class PopupManager {
  final PopupRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  PopupManager(this._remoteDataSource, this._storageService);

  List<PopupModel>? _cachedPopups;
  DateTime? _lastFetchTime;

  Future<List<PopupModel>> getActivePopups({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedPopups != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      return _cachedPopups!;
    }
    _cachedPopups = await _remoteDataSource.getActivePopups();
    _lastFetchTime = DateTime.now();
    return _cachedPopups!;
  }

  /// Evaluates eligible popups for a given context event
  Future<PopupModel?> evaluateEligiblePopup({
    required PopupContextTrigger contextTrigger,
    bool isUserLoggedIn = false,
    bool isVipUser = false,
    bool isNewUser = false,
    int? currentZoneId,
    String? currentCountryId,
    String? currentLanguage,
    int? currentStoreId,
    int? currentCategoryId,
    int? currentProductId,
    double cartSubtotal = 0.0,
    List<int> cartProductIds = const [],
  }) async {
    final popups = await getActivePopups();
    if (popups.isEmpty) return null;

    final sortedPopups = List<PopupModel>.from(popups)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final openCount = _storageService.getAppOpenCount();
    final now = DateTime.now();

    for (final popup in sortedPopups) {
      // 1. Datetime Schedule Check
      if (popup.startAt != null && now.isBefore(popup.startAt!)) continue;
      if (popup.endAt != null && now.isAfter(popup.endAt!)) continue;

      // 2. Audience Check
      if (popup.audienceType == 'new' && !isNewUser) continue;
      if (popup.audienceType == 'existing' && isNewUser) continue;
      if (popup.audienceType == 'vip' && !isVipUser) continue;
      if (popup.audienceType == 'non_vip' && isVipUser) continue;

      // 3. Zone, Country, Language, Store, Category, Product Targeting Check
      if (popup.zoneIds.isNotEmpty &&
          (currentZoneId == null || !popup.zoneIds.contains(currentZoneId))) {
        continue;
      }
      if (popup.countryIds.isNotEmpty &&
          (currentCountryId == null || !popup.countryIds.contains(currentCountryId))) {
        continue;
      }
      if (popup.languageCodes.isNotEmpty &&
          (currentLanguage == null || !popup.languageCodes.contains(currentLanguage))) {
        continue;
      }
      if (popup.storeIds.isNotEmpty &&
          (currentStoreId == null || !popup.storeIds.contains(currentStoreId))) {
        continue;
      }
      if (popup.categoryIds.isNotEmpty &&
          (currentCategoryId == null || !popup.categoryIds.contains(currentCategoryId))) {
        continue;
      }
      if (popup.productIds.isNotEmpty &&
          (currentProductId == null || !popup.productIds.contains(currentProductId)) &&
          !popup.productIds.any((id) => cartProductIds.contains(id))) {
        continue;
      }

      // 4. Frequency & Seen Constraints Check
      if (popup.displayTrigger == 'once_per_user' &&
          _storageService.getSeenPopupIdsUser().contains(popup.id)) {
        continue;
      }
      if (popup.displayTrigger == 'once_per_day' &&
          _storageService.wasPopupShownToday(popup.id)) {
        continue;
      }
      if (popup.displayTrigger == 'once_per_session' &&
          _storageService.wasPopupShownSession(popup.id)) {
        continue;
      }

      // 5. Trigger-specific Match
      bool isMatch = false;

      switch (popup.displayTrigger) {
        case 'first_app_open':
          isMatch = (contextTrigger == PopupContextTrigger.onAppOpen && openCount <= 1);
          break;
        case 'second_app_open':
          isMatch = (contextTrigger == PopupContextTrigger.onAppOpen && openCount == 2);
          break;
        case 'every_app_open':
        case 'once_per_day':
        case 'once_per_session':
        case 'once_per_user':
          isMatch = (contextTrigger == PopupContextTrigger.onAppOpen);
          break;
        case 'after_x_seconds':
          isMatch = (contextTrigger == PopupContextTrigger.onAppOpen);
          break;
        case 'after_x_opens':
          final targetOpens = int.tryParse(popup.triggerValue) ?? 0;
          isMatch = (contextTrigger == PopupContextTrigger.onAppOpen && openCount >= targetOpens);
          break;
        case 'on_app_exit':
          isMatch = (contextTrigger == PopupContextTrigger.onAppExit);
          break;
        case 'after_order_completion':
        case 'after_checkout':
          isMatch = (contextTrigger == PopupContextTrigger.onOrderCompletion);
          break;
        case 'after_login':
          isMatch = (contextTrigger == PopupContextTrigger.onLogin);
          break;
        case 'before_checkout':
          isMatch = (contextTrigger == PopupContextTrigger.onBeforeCheckout);
          break;
        case 'specific_product_in_cart':
          final targetProdId = int.tryParse(popup.triggerValue) ?? 0;
          isMatch = (contextTrigger == PopupContextTrigger.onCartChange ||
                  contextTrigger == PopupContextTrigger.onBeforeCheckout) &&
              cartProductIds.contains(targetProdId);
          break;
        case 'cart_amount_reached':
          final minAmount = double.tryParse(popup.triggerValue) ?? 0.0;
          isMatch = (contextTrigger == PopupContextTrigger.onCartChange ||
                  contextTrigger == PopupContextTrigger.onBeforeCheckout) &&
              cartSubtotal >= minAmount;
          break;
        default:
          isMatch = false;
      }

      if (isMatch) {
        return popup;
      }
    }

    return null;
  }

  /// Mark popup presented to prevent duplicate display according to frequency rule
  Future<void> recordPopupPresented(PopupEntity popup) async {
    _storageService.markPopupShownSession(popup.id);
    if (popup.displayTrigger == 'once_per_day') {
      await _storageService.markPopupShownToday(popup.id);
    }
    if (popup.displayTrigger == 'once_per_user') {
      await _storageService.markPopupSeenUser(popup.id);
    }
  }
}
