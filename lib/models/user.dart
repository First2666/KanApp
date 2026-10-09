class UserModel {
  final int id;
  final String username;
  final String email;
  final int role;
  final String? avatarUrl;
  final String? token;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.token,
  });

  bool get isAdmin => role == 1;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] is int ? json['role'] : (int.tryParse(json['role']?.toString() ?? '0') ?? 0),
      avatarUrl: json['avatarUrl'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'token': token,
    };
  }
}
