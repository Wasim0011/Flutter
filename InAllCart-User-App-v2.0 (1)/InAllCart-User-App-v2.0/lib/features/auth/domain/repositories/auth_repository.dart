import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResult>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
  });

  Future<Either<Failure, User>> getUser();

  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> logoutAll();

  Future<Either<Failure, Map<String, dynamic>>> getAuthConfig();

  Future<Either<Failure, Map<String, dynamic>>> sendPhoneOtp(String phone);

  Future<Either<Failure, AuthResult>> verifyPhoneOtp(String phone, String code, {String? name, String? referralCode});

  Future<Either<Failure, Map<String, dynamic>>> sendEmailOtp(String email);

  Future<Either<Failure, AuthResult>> verifyEmailOtp(
    String email,
    String code, {
    String? name,
    String? phone,
    String? password,
    String? referralCode,
  });

  Future<Either<Failure, AuthResult>> verifyFirebaseToken(String token, {String? phone, String? name, String? referralCode});

  Future<Either<Failure, void>> deleteAccount();

  bool get isLoggedIn;

  User? get currentUser;
}
