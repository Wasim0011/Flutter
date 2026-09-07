import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Login {
  final AuthRepository _repository;

  Login(this._repository);

  Future<Either<Failure, AuthResult>> call({
    required String email,
    required String password,
  }) =>
      _repository.login(email: email, password: password);
}

class Register {
  final AuthRepository _repository;

  Register(this._repository);

  Future<Either<Failure, AuthResult>> call({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
  }) =>
      _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        referralCode: referralCode,
      );
}

class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  Future<Either<Failure, User>> call() => _repository.getUser();
}

class UpdateProfile {
  final AuthRepository _repository;

  UpdateProfile(this._repository);

  Future<Either<Failure, User>> call({
    String? name,
    String? phone,
    String? avatarPath,
  }) =>
      _repository.updateProfile(
        name: name,
        phone: phone,
        avatarPath: avatarPath,
      );
}

class Logout {
  final AuthRepository _repository;

  Logout(this._repository);

  Future<Either<Failure, void>> call() => _repository.logout();
}

class LogoutAll {
  final AuthRepository _repository;

  LogoutAll(this._repository);

  Future<Either<Failure, void>> call() => _repository.logoutAll();
}

class CheckAuthStatus {
  final AuthRepository _repository;

  CheckAuthStatus(this._repository);

  bool call() => _repository.isLoggedIn;
}

class GetAuthConfig {
  final AuthRepository _repository;

  GetAuthConfig(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call() => _repository.getAuthConfig();
}

class SendPhoneOtp {
  final AuthRepository _repository;

  SendPhoneOtp(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String phone) => _repository.sendPhoneOtp(phone);
}

class VerifyPhoneOtp {
  final AuthRepository _repository;

  VerifyPhoneOtp(this._repository);

  Future<Either<Failure, AuthResult>> call(String phone, String code, {String? name, String? referralCode}) =>
      _repository.verifyPhoneOtp(phone, code, name: name, referralCode: referralCode);
}

class SendEmailOtp {
  final AuthRepository _repository;

  SendEmailOtp(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String email) => _repository.sendEmailOtp(email);
}

class VerifyEmailOtp {
  final AuthRepository _repository;

  VerifyEmailOtp(this._repository);

  Future<Either<Failure, AuthResult>> call(
    String email,
    String code, {
    String? name,
    String? phone,
    String? password,
    String? referralCode,
  }) =>
      _repository.verifyEmailOtp(
        email,
        code,
        name: name,
        phone: phone,
        password: password,
        referralCode: referralCode,
      );
}

class VerifyFirebaseToken {
  final AuthRepository _repository;

  VerifyFirebaseToken(this._repository);

  Future<Either<Failure, AuthResult>> call(String token, {String? phone, String? name, String? referralCode}) =>
      _repository.verifyFirebaseToken(token, phone: phone, name: name, referralCode: referralCode);
}

class DeleteAccount {
  final AuthRepository _repository;

  DeleteAccount(this._repository);

  Future<Either<Failure, void>> call() => _repository.deleteAccount();
}
