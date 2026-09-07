import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.type,
    required super.name,
    required super.phone,
    required super.addressLine1,
    super.addressLine2,
    super.landmark,
    required super.city,
    required super.state,
    required super.postalCode,
    super.country,
    super.latitude,
    super.longitude,
    super.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'home',
      name: json['name'] as String,
      phone: json['phone'] as String,
      addressLine1: json['address_line_1'] as String? ?? '',
      addressLine2: json['address_line_2'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postal_code'] as String,
      country: json['country'] as String? ?? 'India',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'phone': phone,
        'address_line_1': addressLine1,
        'address_line_2': addressLine2,
        'landmark': landmark,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };
}
