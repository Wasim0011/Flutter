import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final int id;
  final String type; // home, work, other
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    this.landmark,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'India',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      if (landmark != null && landmark!.isNotEmpty) landmark,
      city,
      state,
      postalCode,
    ];
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        phone,
        addressLine1,
        addressLine2,
        landmark,
        city,
        state,
        postalCode,
        country,
        latitude,
        longitude,
        isDefault,
      ];
}
