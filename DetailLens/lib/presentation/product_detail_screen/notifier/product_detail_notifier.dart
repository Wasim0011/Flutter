import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/services/gemini_service.dart';
import '../../../data/api_key.dart';
import '../models/product_detail_model.dart';
import '../models/product_info_item_model.dart';
import '../../../core/app_export.dart';

part 'product_detail_state.dart';

final productDetailNotifier = StateNotifierProvider.autoDispose<
    ProductDetailNotifier, ProductDetailState>(
  (ref) => ProductDetailNotifier(
    ProductDetailState(
      productDetailModel: ProductDetailModel(),
      isLoading: false,
      error: null,
      productInfoItems: const [],
      isReadingAloud: false,
      isTranslating: false,
    ),
  ),
);

class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  final FlutterTts _flutterTts = FlutterTts();
  final GeminiService _geminiService = GeminiService(geminiApiKey);

  ProductDetailNotifier(ProductDetailState state) : super(state) {
    _flutterTts.setCompletionHandler(() {
      state = state.copyWith(isReadingAloud: false);
    });
    state = state.copyWith(error: null);
  }

  void initializeFromData(Map<String, dynamic> data) {
    try {
      state = state.copyWith(isLoading: true);

      final detailModel = ProductDetailModel.fromJson(data);

      final productInfoItems = [
        ProductInfoItemModel(
          leftModel:
              ProductInfoModel.fromJson("Product Name", data["Product Name"]),
          rightModel: ProductInfoModel.fromJson("Brand", data["Brand"]),
        ),
        ProductInfoItemModel(
          leftModel: ProductInfoModel.fromJson("Weight", data["Weight"]),
          rightModel:
              ProductInfoModel.fromJson("Ingredients", data["Ingredients"]),
        ),
        ProductInfoItemModel(
          leftModel: ProductInfoModel.fromJson(
              "Nutritional Info", data["Nutritional Info"]),
          rightModel: ProductInfoModel.fromJson("Food Type", data["Food Type"]),
        ),
        ProductInfoItemModel(
          leftModel: ProductInfoModel.fromJson("Price", data["Price"]),
          rightModel:
              ProductInfoModel.fromJson("Expiry Date", data["Expiry Date"]),
        ),
        ProductInfoItemModel(
          leftModel: ProductInfoModel.fromJson(
              "Manufacturing Date", data["Manufacturing Date"]),
          rightModel: ProductInfoModel.fromJson(
              "License Number", data["License Number"]),
        ),
        ProductInfoItemModel(
          leftModel: ProductInfoModel.fromJson(
              "Helpline Number", data["Helpline Number"]),
          rightModel: ProductInfoModel.fromJson("Warranty", data["Warranty"]),
        ),
        ProductInfoItemModel(
          leftModel:
              ProductInfoModel.fromJson("Other Info", data["Other Info"]),
        ),
      ];
      state = state.copyWith(
        isLoading: false,
        error: null,
        productDetailModel: detailModel,
        productInfoItems: productInfoItems,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to parse product data: $e",
      );
    }
  }

  Future<void> readAloud() async {
    if (state.isReadingAloud) {
      stopReadingAloud();
      return;
    }
    if (state.isTranslating) return;

    state = state.copyWith(isTranslating: true, error: null);

    final details = StringBuffer();
    details.writeln(
        "Brand: ${state.productDetailModel?.brandName ?? 'Not available'}.");
    state.productInfoItems?.forEach((item) {
      if (item.leftModel?.label != null && item.leftModel?.value != null) {
        details.writeln("${item.leftModel!.label}: ${item.leftModel!.value}.");
      }
      if (item.rightModel?.label != null && item.rightModel?.value != null) {
        details
            .writeln("${item.rightModel!.label}: ${item.rightModel!.value}.");
      }
    });

    try {
      final translatedText =
          await _geminiService.translateToHindi(details.toString());
      if (translatedText != null && translatedText.isNotEmpty) {
        await _flutterTts.setLanguage("hi-IN");

        state = state.copyWith(isTranslating: false, isReadingAloud: true);

        await _flutterTts.speak(translatedText);
      } else {
        state = state.copyWith(
            isTranslating: false,
            isReadingAloud: false,
            error: "Received an empty translation.");
      }
    } catch (e) {
      state = state.copyWith(
        isTranslating: false,
        isReadingAloud: false,
        error: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  void stopReadingAloud() async {
    await _flutterTts.stop();
    state = state.copyWith(isReadingAloud: false, isTranslating: false);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
