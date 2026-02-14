import '../../../core/app_export.dart';

class ProductDetailModel extends Equatable {
  final String? productTitle;
  final String? brandName;

  const ProductDetailModel({
    this.productTitle,
    this.brandName,
  });
  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      productTitle: json["Product Name"],
      brandName: json["Brand"],
    );
  }

  ProductDetailModel copyWith({
    String? productTitle,
    String? brandName,
  }) {
    return ProductDetailModel(
      productTitle: productTitle ?? this.productTitle,
      brandName: brandName ?? this.brandName,
    );
  }

  @override
  List<Object?> get props => [
        productTitle,
        brandName,
      ];
}
