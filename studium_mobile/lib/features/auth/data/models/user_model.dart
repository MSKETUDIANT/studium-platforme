import '../../domain/models/auth_user.dart';

class UserModel extends StudiumUser {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.status,
    required super.createdAt,
  });

  factory UserModel.fromSupabase(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'student',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}