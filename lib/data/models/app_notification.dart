import 'json_utils.dart';

/// An in-app notification (`Notification` interface). Named [AppNotification]
/// to avoid clashing with Flutter's own `Notification` class.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.link,
  });

  final String id;
  final String userId;

  /// One of: `order_update`, `review_received`, `promotion`,
  /// `delivery_update`, `listing_approved`, `listing_rejected`, `system`.
  final String type;
  final String title;
  final String message;
  final bool read;
  final String? link;
  final String createdAt;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      link: link,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      type: Json.str(json['type'], 'system'),
      title: Json.str(json['title']),
      message: Json.str(json['message']),
      read: Json.boolean(json['read']),
      link: Json.strOrNull(json['link']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}
