part of 'product_detail_notifier.dart';

class ProductDetailState extends Equatable {
  final ProductDetailModel? productDetailModel;
  final List<ProductInfoItemModel>? productInfoItems;
  final bool isLoading;
  final String? error;
  final bool isReadingAloud;
  final bool isTranslating;

  const ProductDetailState({
    required this.productDetailModel,
    this.productInfoItems = const [],
    this.isLoading = false,
    this.error,
    this.isReadingAloud = false,
    this.isTranslating = false,
  });

  ProductDetailState copyWith({
    ProductDetailModel? productDetailModel,
    List<ProductInfoItemModel>? productInfoItems,
    bool? isLoading,
    String? error,
    bool? isReadingAloud,
    bool? isTranslating,
  }) {
    return ProductDetailState(
      productDetailModel: productDetailModel ?? this.productDetailModel,
      productInfoItems: productInfoItems ?? this.productInfoItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isReadingAloud: isReadingAloud ?? this.isReadingAloud,
      isTranslating: isTranslating ?? this.isTranslating,
    );
  }

  @override
  List<Object?> get props => [
        productDetailModel,
        productInfoItems,
        isLoading,
        error,
        isReadingAloud,
        isTranslating,
      ];
}
