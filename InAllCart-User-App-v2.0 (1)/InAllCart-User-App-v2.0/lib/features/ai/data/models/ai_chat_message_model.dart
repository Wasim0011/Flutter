import '../../domain/entities/ai_chat_message.dart';
import '../../../products/data/models/product_model.dart';

class AiChatMessageModel {
  final String text;
  final bool isUser;
  final String? image;
  final List<ProductModel>? items;
  final DateTime timestamp;
  final bool hasError;

  AiChatMessageModel({
    required this.text,
    required this.isUser,
    this.image,
    this.items,
    required this.timestamp,
    this.hasError = false,
  });

  factory AiChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AiChatMessageModel(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      image: json['image'] as String?,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => ProductModel.fromJson(e)).toList()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      hasError: json['hasError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'image': image,
      'items': items?.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'hasError': hasError,
    };
  }

  factory AiChatMessageModel.fromEntity(AiChatMessage entity) {
    return AiChatMessageModel(
      text: entity.text,
      isUser: entity.isUser,
      image: entity.image,
      items: entity.items?.map((e) {
        if (e is ProductModel) return e;
        // Fallback or manual conversion if needed
        return ProductModel.fromJson({
          'id': e.id,
          'name': e.name,
          'slug': e.slug,
          'price': {
            'amount': e.price.amount,
            'formatted': e.price.formatted,
            'compare_price': e.price.comparePrice,
          },
          'inventory': {
            'quantity': e.inventory.quantity,
            'in_stock': e.inventory.inStock,
            'is_low_stock': e.inventory.isLowStock,
          },
          'primary_image': e.primaryImage != null ? {'url': e.primaryImage!.url} : null,
          'flags': {'is_active': e.flags.isActive, 'is_featured': e.flags.isFeatured},
        });
      }).toList(),
      timestamp: entity.timestamp,
      hasError: entity.hasError,
    );
  }

  AiChatMessage toEntity() {
    return AiChatMessage(
      text: text,
      isUser: isUser,
      image: image,
      items: items,
      timestamp: timestamp,
      hasError: hasError,
    );
  }
}
