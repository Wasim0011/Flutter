import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/support_ticket_model.dart';

class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository(this._apiClient);

  Future<List<SupportCategory>> getCategories() async {
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(
        '/complaints/categories',
        parser: (d) => d as Map<String, dynamic>,
      );
      final rawList = data['data'] as List? ?? [];
      return rawList.map((e) => SupportCategory.fromJson(e)).toList();
    } catch (_) {
      try {
        final data = await _apiClient.get<Map<String, dynamic>>(
          '/support/categories',
          parser: (d) => d as Map<String, dynamic>,
        );
        final rawList = data['data'] as List? ?? [];
        return rawList.map((e) => SupportCategory.fromJson(e)).toList();
      } catch (_) {
        return const [
          SupportCategory(id: 1, name: 'Food Quality', icon: 'fastfood'),
          SupportCategory(id: 2, name: 'Wrong Item', icon: 'error'),
          SupportCategory(id: 3, name: 'Damaged Packaging', icon: 'inventory_2'),
          SupportCategory(id: 4, name: 'Late Delivery', icon: 'schedule'),
          SupportCategory(id: 5, name: 'Rider Behavior', icon: 'directions_bike'),
          SupportCategory(id: 6, name: 'Missing Item', icon: 'remove_shopping_cart'),
        ];
      }
    }
  }

  Future<List<SupportTicket>> getTickets({int page = 1}) async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/support/tickets',
      queryParameters: {'page': page},
      parser: (d) => d as Map<String, dynamic>,
    );
    final pagination = data['data'] as Map<String, dynamic>;
    return (pagination['data'] as List)
        .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupportTicket> getTicket(int ticketId) async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/support/tickets/$ticketId',
      parser: (d) => d as Map<String, dynamic>,
    );
    return SupportTicket.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<SupportTicket> createTicket({
    required int categoryId,
    required String subject,
    required String description,
    List<File>? attachments,
  }) async {
    FormData? formData;
    if (attachments != null && attachments.isNotEmpty) {
      final files = await Future.wait(
        attachments.map((f) async => await MultipartFile.fromFile(f.path)),
      );
      formData = FormData.fromMap({
        'category_id': categoryId,
        'subject': subject,
        'description': description,
        'attachments': files,
      });
    }

    final data = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/support/tickets',
      data: formData ??
          {
            'category_id': categoryId,
            'subject': subject,
            'description': description,
          },
      parser: (d) => d as Map<String, dynamic>,
    );
    return SupportTicket.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<SupportMessage> sendMessage({
    required int ticketId,
    required String message,
    List<File>? attachments,
  }) async {
    FormData? formData;
    if (attachments != null && attachments.isNotEmpty) {
      final files = await Future.wait(
        attachments.map((f) async => await MultipartFile.fromFile(f.path)),
      );
      formData = FormData.fromMap({
        'message': message,
        'attachments': files,
      });
    }

    final data = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/support/tickets/$ticketId/messages',
      data: formData ?? {'message': message},
      parser: (d) => d as Map<String, dynamic>,
    );
    return SupportMessage.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> initChat(int ticketId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/support/tickets/$ticketId/chat/init',
      parser: (d) => d as Map<String, dynamic>,
    );
  }

  Future<void> closeTicket(int ticketId) async {
    await _apiClient.post('/api/v1/support/tickets/$ticketId/close');
  }
}
