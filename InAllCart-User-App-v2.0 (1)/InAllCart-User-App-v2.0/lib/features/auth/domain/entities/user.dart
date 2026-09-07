import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  bool get isEmailVerified => emailVerifiedAt != null;

  @override
  List<Object?> get props => [id, name, email, phone, avatar, emailVerifiedAt, createdAt];
}

class AuthResult {
  final User user;
  final String token;
  final String tokenType;
  final bool isNewUser;

  const AuthResult({
    required this.user,
    required this.token,
    this.tokenType = 'Bearer',
    this.isNewUser = false,
  });
}
