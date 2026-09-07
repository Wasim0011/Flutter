/// Model for `hs_service_types` rows returned by the API.
///
/// API response shape (ServiceTypeController::index):
///   id, name, slug, description, icon, icon_url, capacity,
///   base_fee, per_km_rate, per_hour_rate, minimum_fee, cancellation_fee
class ServiceTypeModel {
  final int id;
  final String name;
  final String slug;
  final String description;

  /// Resolved icon value: full URL when admin uploaded an image,
  /// null otherwise. Use [HsIcons.placeholder] as fallback in the UI.
  final String? icon;

  final double baseFee;
  final double perKmRate;
  final double perHourRate;
  final double minimumFee;
  final double cancellationFee;
  final int capacity;

  ServiceTypeModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.icon,
    required this.baseFee,
    required this.perKmRate,
    required this.perHourRate,
    required this.minimumFee,
    required this.cancellationFee,
    required this.capacity,
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id:              json['id'] as int,
      name:            json['name'] as String? ?? '',
      slug:            json['slug'] as String? ?? '',
      description:     json['description'] as String? ?? '',
      // icon_url is the resolved full URL; fall back to raw icon field
      icon:            json['icon_url'] as String? ?? json['icon'] as String?,
      baseFee:         double.tryParse(json['base_fee']?.toString() ?? '')         ?? 0.0,
      perKmRate:       double.tryParse(json['per_km_rate']?.toString() ?? '')       ?? 0.0,
      perHourRate:     double.tryParse(json['per_hour_rate']?.toString() ?? '')     ?? 0.0,
      minimumFee:      double.tryParse(json['minimum_fee']?.toString() ?? '')       ?? 0.0,
      cancellationFee: double.tryParse(json['cancellation_fee']?.toString() ?? '')  ?? 0.0,
      capacity:        int.tryParse(json['capacity']?.toString() ?? '')             ?? 1,
    );
  }

  /// Human-readable capacity label shown in the vehicle selector.
  String get capacityDisplay => 'Up to $capacity helpers';
}
