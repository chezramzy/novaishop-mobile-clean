import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/json_utils.dart';
import 'repository_error.dart';

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
    required this.unreadCount,
    required this.page,
    required this.totalPages,
  });

  final List<AppNotification> items;
  final int total;
  final int unreadCount;
  final int page;
  final int totalPages;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    return NotificationPage(
      items: Json.list(json['items'], AppNotification.fromJson),
      total: Json.integer(json['total']),
      unreadCount: Json.integer(json['unreadCount']),
      page: Json.integer(json['page'], 1),
      totalPages: Json.integer(json['totalPages']),
    );
  }
}

class NotificationRepository {
  NotificationRepository({required String? accessToken})
      : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSession =>
      Supabase.instance.client.auth.currentSession != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession() {
    if (!_hasSession) {
      throw RepositoryException(
          'Reconnectez-vous pour voir vos notifications.');
    }
  }

  Future<NotificationPage> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    _requireSession();
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .range(from, to);
      final items = rows
          .whereType<Map>()
          .map((row) => AppNotification.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList();
      final unreadCount = await getUnreadCount();
      return NotificationPage(
        items: items,
        total: items.length,
        unreadCount: unreadCount,
        page: page,
        totalPages: items.isEmpty ? 0 : page,
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<int> getUnreadCount() async {
    if (!_hasSession) return 0;
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', _userId)
          .eq('read', false);
      return rows.length;
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<AppNotification> markRead(String notificationId) async {
    _requireSession();
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId)
          .eq('user_id', _userId)
          .select()
          .limit(1);
      return AppNotification.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<void> markAllRead() async {
    _requireSession();
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', _userId)
          .eq('read', false);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  String get _userId {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw RepositoryException('Session introuvable. Reconnectez-vous.');
    }
    return id;
  }
}
