import '../../domain/entities/popup.dart';

class PopupModel extends PopupEntity {
  const PopupModel({
    required super.id,
    required super.name,
    required super.mediaUrl,
    required super.mediaType,
    required super.status,
    required super.position,
    required super.showCloseButton,
    required super.clickAction,
    required super.clickActionTarget,
    required super.displayTrigger,
    required super.triggerValue,
    required super.audienceType,
    required super.zoneIds,
    required super.countryIds,
    required super.languageCodes,
    required super.storeIds,
    required super.categoryIds,
    required super.productIds,
    required super.priority,
    super.startAt,
    super.endAt,
  });

  factory PopupModel.fromJson(Map<String, dynamic> json) {
    List<int> parseIntList(dynamic val) {
      if (val is List) {
        return val.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
      }
      return [];
    }

    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return PopupModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      status: json['status'] ?? 'active',
      position: json['position'] ?? 'center',
      showCloseButton: json['show_close_button'] == true || json['show_close_button'] == 1 || json['show_close_button'] == '1',
      clickAction: json['click_action'] ?? 'none',
      clickActionTarget: json['click_action_target']?.toString() ?? '',
      displayTrigger: json['display_trigger'] ?? 'every_app_open',
      triggerValue: json['trigger_value']?.toString() ?? '',
      audienceType: json['audience_type'] ?? 'all',
      zoneIds: parseIntList(json['zone_ids']),
      countryIds: parseStringList(json['country_ids']),
      languageCodes: parseStringList(json['language_codes']),
      storeIds: parseIntList(json['store_ids']),
      categoryIds: parseIntList(json['category_ids']),
      productIds: parseIntList(json['product_ids']),
      priority: json['priority'] is int ? json['priority'] : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      startAt: json['start_at'] != null ? DateTime.tryParse(json['start_at'].toString()) : null,
      endAt: json['end_at'] != null ? DateTime.tryParse(json['end_at'].toString()) : null,
    );
  }
}
