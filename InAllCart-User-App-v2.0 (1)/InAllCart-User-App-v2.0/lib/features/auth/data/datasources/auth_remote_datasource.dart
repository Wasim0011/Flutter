import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResultModel> login({
    required String email,
    required String password,
  });

  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
  });

  Future<UserModel> getUser();

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  });

  Future<void> logout();

  Future<void> logoutAll();

  Future<Map<String, dynamic>> getAuthConfig();

  Future<Map<String, dynamic>> sendPhoneOtp(String phone);

  Future<AuthResultModel> verifyPhoneOtp(String phone, String code, {String? name, String? referralCode});

  Future<Map<String, dynamic>> sendEmailOtp(String email);

  Future<AuthResultModel> verifyEmailOtp(
    String email,
    String code, {
    String? name,
    String? phone,
    String? password,
    String? referralCode,
  });

  Future<AuthResultModel> verifyFirebaseToken(String token, {String? phone, String? name, String? referralCode});
  
  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResultModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // ApiClient.post returns the response.data directly (Map<String, dynamic>)
      final responseData = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (responseData['success'] == true) {
        return AuthResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }

      throw ServerException(
        message: responseData['message'] as String? ?? 'Login failed',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Login failed: $e');
    }
  }

  @override
  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
  }) async {
    try {
      final responseData = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          if (phone != null) 'phone': phone,
          if (referralCode != null) 'referral_code': referralCode,
        },
      );

      if (responseData['success'] == true) {
        return AuthResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }

      throw ServerException(
        message: responseData['message'] as String? ?? 'Registration failed',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Registration failed: $e');
    }
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final responseData = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.user);

      if (responseData['success'] == true) {
        return UserModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }

      throw ServerException(
        message: responseData['message'] as String? ?? 'Failed to get user',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get user: $e');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      // Avatar upload is handled separately via the dedicated uploadAvatar endpoint.
      // The avatarPath parameter is intentionally unused here.
      
      final responseData = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.updateProfile,
        data: data,
      );

      if (responseData['success'] == true) {
        return UserModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }

      throw ServerException(
        message: responseData['message'] as String? ?? 'Failed to update profile',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to update profile: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // Silent fail - we'll clear local data anyway
    }
  }

  @override
  Future<void> logoutAll() async {
    try {
      await _apiClient.post(ApiEndpoints.logoutAll);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<Map<String, dynamic>> getAuthConfig() async {
    try {
      final responseData = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.authConfig);
      
      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {}; // Default fallbacks will be used
    }
  }

  @override
  Future<Map<String, dynamic>> sendPhoneOtp(String phone) async {
    try {
      final responseData = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.sendPhoneOtp,
        data: {'phone': phone},
      );

      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>? ?? {};
      }
      
      throw ServerException(
        message: responseData['message'] as String? ?? 'Failed to send OTP',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to send OTP: $e');
    }
  }

  @override
  Future<AuthResultModel> verifyPhoneOtp(String phone, String code, {String? name, String? referralCode}) async {
    try {
      final responseData = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyPhoneOtp,
        data: {
          'phone': phone,
          'code': code,
          if (name != null) 'name': name,
          if (referralCode != null) 'referral_code': referralCode,
        },
      );

      if (responseData['success'] == true) {
        return AuthResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      
      throw ServerException(
        message: responseData['message'] as String? ?? 'Verification failed',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Verification failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    try {
      final responseData = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.sendEmailOtp,
        data: {'email': email},
      );

      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>? ?? {};
      }
      
      throw ServerException(
        message: responseData['message'] as String? ?? 'Failed to send OTP',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to send OTP: $e');
    }
  }

  @override
  Future<AuthResultModel> verifyEmailOtp(
    String email,
    String code, {
    String? name,
    String? phone,
    String? password,
    String? referralCode,
  }) async {
    try {
      final responseData = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyEmailOtp,
        data: {
          'email': email,
          'code': code,
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (password != null) 'password': password,
          if (referralCode != null) 'referral_code': referralCode,
        },
      );

      if (responseData['success'] == true) {
        return AuthResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }

      throw ServerException(
        message: responseData['message'] as String? ?? 'Verification failed',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Verification failed: $e');
    }
  }

  @override
  Future<AuthResultModel> verifyFirebaseToken(String token, {String? phone, String? name, String? referralCode}) async {
    try {
      final responseData = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyPhoneOtp, // Re-using this endpoint which checks for firebase_token
        data: {
          'firebase_token': token,
          if (phone != null) 'phone': phone,
          if (name != null) 'name': name,
          if (referralCode != null) 'referral_code': referralCode,
        },
      );

      if (responseData['success'] == true) {
        return AuthResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      
      throw ServerException(
        message: responseData['message'] as String? ?? 'Verification failed',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Verification failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final responseData = await _apiClient.delete<Map<String, dynamic>>(ApiEndpoints.deleteAccount);

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['message'] as String? ?? 'Failed to delete account',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to delete account: $e');
    }
  }
}
