import 'json_utils.dart';

/// A marketplace user as returned by the API (`User` interface).
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;

  /// One of: `client`, `seller`, `admin`, `driver`.
  final String role;
  final String createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: Json.str(json['id']),
      name: Json.str(json['name']),
      email: Json.str(json['email']),
      role: Json.str(json['role'], 'client'),
      createdAt: Json.str(json['createdAt']),
    );
  }
}
