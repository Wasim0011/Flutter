/// Model for `hs_addon_services` rows returned by the API.
///
/// API response shape (AddonController::index):
///   id, name, slug, description, price, type, icon, icon_url
class AddonServiceModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;

  /// DB enum: packing | unpacking | insurance | reassembly | storage | cleaning | other
  final String type;

  /// Resolved icon value: full URL when admin uploaded an image, null otherwise.
  final String? icon;

  AddonServiceModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.type,
    this.icon,
  });

  factory AddonServiceModel.fromJson(Map<String, dynamic> json) {
    return AddonServiceModel(
      id:          json['id'] as int,
      name:        json['name'] as String? ?? '',
      slug:        json['slug'] as String? ?? '',
      description: json['description'] as String?,
      price:       double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      // API may send `type` or legacy `pricing_type`
      type:        json['type'] as String? ?? json['pricing_type'] as String? ?? 'other',
      // icon_url is the resolved full URL; fall back to raw icon field
      icon:        json['icon_url'] as String? ?? json['icon'] as String?,
    );
  }

  bool get isInsurance => type == 'insurance';
}
