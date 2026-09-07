import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../products/domain/entities/product.dart';
import '../entities/ai_chat_message.dart';

abstract class AiRepository {
  Future<Either<Failure, AiChatResponse>> sendMessage(String message, {List<Map<String, dynamic>>? history, String? image});
  Future<Either<Failure, List<AiChatMessage>>> getChatHistory();
  Future<Either<Failure, void>> saveMessage(AiChatMessage message);
  Future<Either<Failure, void>> clearHistory();
}

class AiChatResponse {
  final String message;
  final List<Product> items;

  AiChatResponse({required this.message, required this.items});
}
