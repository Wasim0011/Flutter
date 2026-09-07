import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/address_model.dart';

abstract class AddressRemoteDataSource {
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> getAddressById(int id);
  Future<AddressModel> createAddress(Map<String, dynamic> data);
  Future<AddressModel> updateAddress(int id, Map<String, dynamic> data);
  Future<void> deleteAddress(int id);
  Future<AddressModel> setDefaultAddress(int id);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final ApiClient _apiClient;

  AddressRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<AddressModel>> getAddresses() async {
    final responseData = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.addresses);
    final data = responseData['data'] as List;
    return data.map((e) => AddressModel.fromJson(e)).toList();
  }

  @override
  Future<AddressModel> getAddressById(int id) async {
    final responseData = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.addressDetails(id.toString()));
    return AddressModel.fromJson(responseData['data']);
  }

  @override
  Future<AddressModel> createAddress(Map<String, dynamic> data) async {
    final responseData = await _apiClient.post<Map<String, dynamic>>(ApiEndpoints.addresses, data: data);
    return AddressModel.fromJson(responseData['data']);
  }

  @override
  Future<AddressModel> updateAddress(int id, Map<String, dynamic> data) async {
    final responseData = await _apiClient.put<Map<String, dynamic>>(ApiEndpoints.addressDetails(id.toString()), data: data);
    return AddressModel.fromJson(responseData['data']);
  }

  @override
  Future<void> deleteAddress(int id) async {
    await _apiClient.delete(ApiEndpoints.addressDetails(id.toString()));
  }

  @override
  Future<AddressModel> setDefaultAddress(int id) async {
    final responseData = await _apiClient.post<Map<String, dynamic>>(ApiEndpoints.setDefaultAddress(id.toString()));
    return AddressModel.fromJson(responseData['data']);
  }
}
