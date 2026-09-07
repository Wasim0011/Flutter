import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

class AiChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final String? image;
  final List<Product>? items;
  final DateTime timestamp;
  final bool hasError;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    this.image,
    this.items,
    required this.timestamp,
    this.hasError = false,
  });

  @override
  List<Object?> get props => [text, isUser, image, items, timestamp, hasError];
}
