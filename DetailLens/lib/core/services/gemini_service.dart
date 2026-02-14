import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

String _getMimeType(File file) {
  final ext = file.path.split('.').last.toLowerCase();

  switch (ext) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    default:
      return 'application/octet-stream'; // fallback
  }
}

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig:
              GenerationConfig(responseMimeType: 'application/json'),
        );

  // Accept a list of images
  Future<String?> fetchProductDetails(List<File> images) async {
    if (images.isEmpty) {
      return null;
    }
    try {
      // Create a list of DataParts from the image files
      final imageParts = await Future.wait(images.map((file) async {
        return DataPart(_getMimeType(file), await file.readAsBytes());
      }).toList());

      final content = [
        Content.multi([
          ...imageParts, // Spread the list of image parts
          TextPart("""
          Analyze the provided product images. Extract the specified details.
          Respond ONLY with a valid JSON object matching this exact structure. Do not include any extra text, conversational phrases, or markdown formatting.
          If a value is not found, use "Not Present" as the string value. Please give extra attention in extracting Price, Expiry Date and Manufacturing Date as these there are
          most important and wrong information is fatal.

          **IMPORTANT**: If the expiry date is provided in a relative format (e.g., "Best before 12 months from manufacture date"), you MUST calculate the absolute expiry
          date based on the "Manufacturing Date" and place the calculated date in the "Expiry Date" field.

          {
            "Product Name": "...",
            "Brand": "...",
            "Weight": "...",
            "Ingredients": "...",
            "Nutritional Info": "...",
            "Food Type": "...",
            "Price": "...",
            "Expiry Date": "...",
            "Manufacturing Date": "...",
            "License Number": "...",
            "Helpline Number": "...",
            "Warranty": "...",
            "Other Info": "..."
          }
          """),
        ]),
      ];

      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print("Gemini Service Error: $e");
      rethrow;
    }
  }

  Future<String?> translateToHindi(String text) async {
    try {
      final content = [
        Content.text(
            'Translate the following English text to Indian Hindi: "$text"')
      ];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print("Gemini Service Error (Translation): $e");
      throw Exception(
          'Translation failed. Please check your API key and network connection.');
    }
  }
}
