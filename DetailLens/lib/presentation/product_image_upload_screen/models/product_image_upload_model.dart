import '../../../core/app_export.dart';

// ignore_for_file: must_be_immutable
class ProductImageUploadModel extends Equatable {
  ProductImageUploadModel({
    this.imagePaths,
    this.uploadStatus,
    this.extractedDetails,
    this.id,
  }) {
    imagePaths = imagePaths ?? []; //Default to an empty list
    uploadStatus = uploadStatus ?? 'pending';
    id = id ?? '';
    extractedDetails = extractedDetails ?? {};
  }

  List<String>? imagePaths;
  String? uploadStatus;
  Map<String, dynamic>? extractedDetails;
  String? id;

  ProductImageUploadModel copyWith({
    List<String>? imagePaths,
    String? uploadStatus,
    Map<String, dynamic>? extractedDetails,
    String? id,
  }) {
    return ProductImageUploadModel(
      imagePaths: imagePaths ?? this.imagePaths,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      extractedDetails: extractedDetails ?? this.extractedDetails,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [imagePaths, uploadStatus, extractedDetails, id];
}
