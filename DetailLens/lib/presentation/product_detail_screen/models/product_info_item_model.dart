import '../../../core/app_export.dart';

// Represents a single piece of product information.
class ProductInfoItemModel extends Equatable {
  final ProductInfoModel? leftModel;
  final ProductInfoModel? rightModel;

  const ProductInfoItemModel({
    this.leftModel,
    this.rightModel,
  });

  ProductInfoItemModel copyWith({
    ProductInfoModel? leftModel,
    ProductInfoModel? rightModel,
  }) {
    return ProductInfoItemModel(
      leftModel: leftModel ?? this.leftModel,
      rightModel: rightModel ?? this.rightModel,
    );
  }

  @override
  List<Object?> get props => [
        leftModel,
        rightModel,
      ];
}

class ProductInfoModel extends Equatable {
  final String? label;
  final String? value;

  const ProductInfoModel({
    this.label,
    this.value,
  });

  factory ProductInfoModel.fromJson(String label, dynamic value) {
    return ProductInfoModel(
      label: label,
      value: value?.toString(),
    );
  }

  ProductInfoModel copyWith({
    String? label,
    String? value,
  }) {
    return ProductInfoModel(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [
        label,
        value,
      ];
}
