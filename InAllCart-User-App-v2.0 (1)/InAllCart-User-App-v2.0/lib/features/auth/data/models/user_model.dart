import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatar,
    super.emailVerifiedAt,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle timestamps - API returns nested timestamps object
    final timestamps = json['timestamps'] as Map<String, dynamic>?;
    final createdAtStr = timestamps?['created_at'] ?? json['created_at'];
    
    // Handle email_verified - API returns boolean, not datetime
    DateTime? emailVerifiedAt;
    if (json['email_verified_at'] != null) {
      emailVerifiedAt = DateTime.parse(json['email_verified_at']);
    } else if (json['email_verified'] == true) {
      // If email_verified is true but no datetime, use current time
      emailVerifiedAt = DateTime.now();
    }

    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      emailVerifiedAt: emailVerifiedAt,
      createdAt: createdAtStr != null
          ? DateTime.parse(createdAtStr)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class AuthResultModel {
  final UserModel user;
  final String token;
  final String tokenType;
  final bool isNewUser;

  const AuthResultModel({
    required this.user,
    required this.token,
    this.tokenType = 'Bearer',
    this.isNewUser = false,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    return AuthResultModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  AuthResult toEntity() => AuthResult(
        user: user,
        token: token,
        tokenType: tokenType,
        isNewUser: isNewUser,
      );
}
