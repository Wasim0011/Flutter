part of 'product_image_upload_notifier.dart';

class ProductImageUploadState extends Equatable {
  final ProductImageUploadModel? productImageUploadModel;
  final bool isLoading;
  final bool? canExtract;
  final bool? extractionStarted;
  final bool? extractionCompleted;
  final String? userMessage;
  final bool isError;

  ProductImageUploadState({
    this.productImageUploadModel,
    this.isLoading = false,
    this.canExtract,
    this.extractionStarted,
    this.extractionCompleted,
    this.userMessage,
    this.isError = false,
  });

  @override
  List<Object?> get props => [
    productImageUploadModel,
    isLoading,
    canExtract,
    extractionStarted,
    extractionCompleted,
    userMessage,
    isError,
  ];

  ProductImageUploadState copyWith({
    ProductImageUploadModel? productImageUploadModel,
    bool? isLoading,
    bool? canExtract,
    bool? extractionStarted,
    bool? extractionCompleted,
    String? userMessage,
    bool? isError,
  }) {
    return ProductImageUploadState(
      productImageUploadModel:
      productImageUploadModel ?? this.productImageUploadModel,
      isLoading: isLoading ?? this.isLoading,
      canExtract: canExtract ?? this.canExtract,
      extractionStarted: extractionStarted ?? this.extractionStarted,
      extractionCompleted: extractionCompleted ?? this.extractionCompleted,
      userMessage: userMessage,
      isError: isError ?? this.isError,
    );
  }
}