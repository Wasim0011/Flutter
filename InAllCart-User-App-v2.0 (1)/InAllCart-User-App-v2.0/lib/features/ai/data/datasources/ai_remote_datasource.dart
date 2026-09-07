import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../../products/data/models/product_model.dart';

abstract class AiRemoteDataSource {
  Future<AiChatResponse> sendMessage(String message, {List<Map<String, dynamic>>? history, String? image});
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final ApiClient client;

  AiRemoteDataSourceImpl(this.client);

  @override
  Future<AiChatResponse> sendMessage(String message, {List<Map<String, dynamic>>? history, String? image}) async {
    final data = await client.post(
      ApiEndpoints.aiChat,
      data: {
        'message': message,
        if (history != null) 'history': history,
        if (image != null) 'image': image,
      },
    );

    if (data['success'] == true) {
      final List<dynamic> itemsJson = data['items'] ?? [];
      final items = itemsJson.map((e) => ProductModel.fromJson(e)).toList();
      
      return AiChatResponse(
        message: data['message'],
        items: items,
      );
    } else {
      throw ServerException(message: data['message'] ?? 'Unknown error');
    }
  }
}
