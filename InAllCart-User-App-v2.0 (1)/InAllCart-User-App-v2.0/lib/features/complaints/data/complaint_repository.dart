import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/complaint_model.dart';

class ComplaintRepository {
  final ApiClient _apiClient;

  ComplaintRepository(this._apiClient);

  Future<List<String>> getCategories() async {
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/complaints/categories',
        parser: (d) => d as Map<String, dynamic>,
      );
      final rawList = data['data'] as List? ?? [];
      return rawList.map((e) => e.toString()).toList();
    } catch (_) {
      return const [
        'Food Quality',
        'Wrong Item',
        'Damaged Packaging',
        'Late Delivery',
        'Rider Behavior',
        'Missing Item',
      ];
    }
  }

  Future<List<CustomerComplaintModel>> getComplaints({int page = 1}) async {
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/complaints',
        queryParameters: {'page': page},
        parser: (d) => d as Map<String, dynamic>,
      );
      final pagination = data['data'] as Map<String, dynamic>? ?? {};
      final list = (pagination['data'] as List? ?? []);
      return list.map((e) => CustomerComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<CustomerComplaintModel> fileComplaint({
    int? orderId,
    required String category,
    required String description,
    List<File>? attachments,
  }) async {
    final Map<String, dynamic> body = {
      if (orderId != null) 'order_id': orderId,
      'category': category,
      'description': description,
    };

    dynamic postData = body;
    if (attachments != null && attachments.isNotEmpty) {
      final List<MultipartFile> files = [];
      for (final file in attachments) {
        files.add(await MultipartFile.fromFile(file.path));
      }
      postData = FormData.fromMap({
        ...body,
        'attachments[]': files,
      });
    }

    final data = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/complaints',
      data: postData,
      parser: (d) => d as Map<String, dynamic>,
    );

    return CustomerComplaintModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
