import 'dart:convert';
class User {
  String? id;
  String username;
  String password;
  String email;
  String? avatar;
  DateTime createdAt;
  DateTime lastActive;
  String role;


  // Constructor
  User({
    this.id,
    required this.username,
    required this.password,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.lastActive,
    this.role = 'regular',
  });

  // Phương thức chuyển đổi đối tượng User thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'role': role,
    };
  }

  // Factory method tạo đối tượng User từ Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(), // Handle potential null from DB query results before conversion
      username: map['username'],
      password: map['password'],
      email: map['email'],
      avatar: map['avatar'],
      createdAt: DateTime.parse(map['createdAt']),
      lastActive: DateTime.parse(map['lastActive']),
      role: map['role'] ?? 'regular',
    );
  }

  // Phương thức chuyển đổi đối tượng User thành chuỗi JSON
  String toJSON() {
    return jsonEncode(toMap());
  }

  // Factory method tạo đối tượng User từ chuỗi JSON
  factory User.fromJSON(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    return User.fromMap(map);
  }

  // Phương thức tạo bản sao (copy) của đối tượng User
  User copyWith({
    String? id,
    String? username,
    String? password,
    String? email,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastActive,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      role: role ?? this.role,
    );
  }

  // Phương thức biểu diễn chuỗi của đối tượng User (để debug)
  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, avatar: $avatar, createdAt: $createdAt, lastActive: $lastActive, role: $role}';
  }
}