class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // 'user' atau 'admin'

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'user',
    );
  }
}
