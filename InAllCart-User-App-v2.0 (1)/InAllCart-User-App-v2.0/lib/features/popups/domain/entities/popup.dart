import 'package:equatable/equatable.dart';

class PopupEntity extends Equatable {
  final int id;
  final String name;
  final String mediaUrl;
  final String mediaType; // 'image' | 'gif'
  final String status; // 'active', 'scheduled', etc.
  final String position; // 'center', 'top', 'bottom', 'floating', 'full_screen'
  final bool showCloseButton;
  final String clickAction; // 'none', 'url', 'page', 'product', 'category', 'store', 'coupon', 'membership'
  final String clickActionTarget;
  final String displayTrigger; // 'first_app_open', 'second_app_open', 'every_app_open', 'once_per_day', 'once_per_session', 'once_per_user', 'after_x_seconds', 'after_x_opens', 'on_app_exit', 'after_order_completion', 'after_login', 'before_checkout', 'after_checkout', 'specific_product_in_cart', 'cart_amount_reached'
  final String triggerValue;
  final String audienceType; // 'all', 'new', 'existing', 'vip', 'non_vip'
  final List<int> zoneIds;
  final List<String> countryIds;
  final List<String> languageCodes;
  final List<int> storeIds;
  final List<int> categoryIds;
  final List<int> productIds;
  final int priority;
  final DateTime? startAt;
  final DateTime? endAt;

  const PopupEntity({
    required this.id,
    required this.name,
    required this.mediaUrl,
    required this.mediaType,
    required this.status,
    required this.position,
    required this.showCloseButton,
    required this.clickAction,
    required this.clickActionTarget,
    required this.displayTrigger,
    required this.triggerValue,
    required this.audienceType,
    required this.zoneIds,
    required this.countryIds,
    required this.languageCodes,
    required this.storeIds,
    required this.categoryIds,
    required this.productIds,
    required this.priority,
    this.startAt,
    this.endAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        mediaUrl,
        mediaType,
        status,
        position,
        showCloseButton,
        clickAction,
        clickActionTarget,
        displayTrigger,
        triggerValue,
        audienceType,
        zoneIds,
        countryIds,
        languageCodes,
        storeIds,
        categoryIds,
        productIds,
        priority,
        startAt,
        endAt,
      ];
}
