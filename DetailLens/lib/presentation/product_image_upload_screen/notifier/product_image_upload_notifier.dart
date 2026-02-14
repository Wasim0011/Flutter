import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:DetailLens/data/api_key.dart';
import '../../../core/app_export.dart';
import '../../../core/services/gemini_service.dart';
import '../models/product_image_upload_model.dart';


part 'product_image_upload_state.dart';

final productImageUploadNotifier = StateNotifierProvider.autoDispose<
    ProductImageUploadNotifier, ProductImageUploadState>(
      (ref) => ProductImageUploadNotifier(
    ProductImageUploadState(
      productImageUploadModel: ProductImageUploadModel(),
    ),
  ),
);

class ProductImageUploadNotifier extends StateNotifier<ProductImageUploadState> {
  ProductImageUploadNotifier(ProductImageUploadState state) : super(state);

  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 5;

  /// Pick multiple images from the gallery or a single image from the camera.
  Future<void> pickImages(ImageSource source) async {
    final currentImages = state.productImageUploadModel?.imagePaths ?? [];
    if (currentImages.length >= maxImages) {
      state = state.copyWith(
          userMessage: "You can only upload a maximum of 5 images.");
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final pickedFiles = await _picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1280,
        );
        if (pickedFiles.isEmpty) return;

        final newPaths = pickedFiles.map((file) => file.path).toList();
        final combined = [...currentImages, ...newPaths];

        if (combined.length > maxImages) {
          state = state.copyWith(
              userMessage: "You can only select up to 5 images in total.",
              isError: true);
          // Only take the first 5
          final truncated = combined.sublist(0, maxImages);
          _updateImageList(truncated);
        } else {
          _updateImageList(combined);
        }
      } else { // Camera
        final pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1280,
        );
        if (pickedFile == null) return;

        final combined = [...currentImages, pickedFile.path];
        _updateImageList(combined);
      }
    } catch (e) {
      debugPrint("pickImages error: $e");
      state = state.copyWith(userMessage: "Failed to add images: $e", isError: true);
    }
  }

  /// Remove an image from the list by its index.
  void removeImage(int index) {
    final currentImages = List<String>.from(state.productImageUploadModel?.imagePaths ?? []);
    if (index >= 0 && index < currentImages.length) {
      currentImages.removeAt(index);
      _updateImageList(currentImages);
    }
  }

  /// Helper to update state with a new list of images.
  void _updateImageList(List<String> newImageList) {
    final updatedModel = state.productImageUploadModel?.copyWith(imagePaths: newImageList);
    state = state.copyWith(
      productImageUploadModel: updatedModel,
      canExtract: newImageList.isNotEmpty,
      userMessage: "Image updated.",
    );
  }

  /// Call Gemini API and extract product details
  Future<Map<String, dynamic>?> extractDetails() async {
    if (!(state.canExtract ?? false)) return null;

    final imagePaths = state.productImageUploadModel?.imagePaths;
    if (imagePaths == null || imagePaths.isEmpty) {
      state = state.copyWith(userMessage: "Please upload at least one image.");
      return null;
    }

    state = state.copyWith(isLoading: true, extractionStarted: true, userMessage: null);
    try {
      final imageFiles = imagePaths.map((path) => File(path)).toList();
      final gemini = GeminiService(geminiApiKey);
      final response = await gemini.fetchProductDetails(imageFiles); // Pass the list

      if (response == null || response.isEmpty) {
        throw Exception("Received an empty response from the server.");
      }

      final cleaned = _extractJson(response);
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      final updatedModel = state.productImageUploadModel?.copyWith(
        extractedDetails: parsed,
      );

      state = state.copyWith(
        isLoading: false,
        extractionCompleted: true,
        productImageUploadModel: updatedModel,
      );
      return parsed;
    } catch (e) {
      debugPrint("extractDetails error: $e");
      // Clean up the error message for the user
      String errorMessage = e.toString();

      // Check for GenerativeAIException message pattern
      if (errorMessage.contains("GenerativeAIException")) {
        final match = RegExp(r'"message":\s*"([^"]*)"').firstMatch(errorMessage);
        if (match != null && match.group(1) != null) {
          errorMessage = match.group(1)!;
        } else {
          errorMessage = "A Gemini API error occurred. Please try again.";
        }
      } else if (errorMessage.startsWith("Exception: ")) {
        // Remove "Exception: " prefix
        errorMessage = errorMessage.substring(11);
      }

      state = state.copyWith(
        isLoading: false,
        extractionCompleted: false,
        userMessage: "Extraction failed: $errorMessage",
        isError: true,
      );
      return null;
    }
  }

  String _extractJson(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start == -1 || end == -1) {
      throw Exception("No valid JSON object found in the response.");
    }
    return response.substring(start, end + 1);
  }

  void clearUserMessage() {
    state = state.copyWith(userMessage: null);
  }

  void resetState() {
    state = ProductImageUploadState(
      productImageUploadModel: ProductImageUploadModel(),
    );
  }
}