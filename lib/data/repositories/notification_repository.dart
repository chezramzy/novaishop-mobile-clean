import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/json_utils.dart';

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

  static const _readKey = 'novaishop.local.read_notifications';

  final String? _accessToken;

  Future<NotificationPage> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final generated = await _partnerApprovalNotification();
    final readIds = await _readIds();
    final items = <AppNotification>[
      if (generated != null)
        generated.copyWith(read: readIds.contains(generated.id)),
    ];
    return NotificationPage(
      items: items,
      total: items.length,
      unreadCount: items.where((item) => !item.read).length,
      page: page,
      totalPages: items.isEmpty ? 0 : 1,
    );
  }

  Future<int> getUnreadCount() async {
    final page = await getNotifications(pageSize: 1);
    return page.unreadCount;
  }

  Future<AppNotification> markRead(String notificationId) async {
    final ids = await _readIds();
    ids.add(notificationId);
    await _saveReadIds(ids);
    final page = await getNotifications();
    return page.items.firstWhere(
      (item) => item.id == notificationId,
      orElse: () => throw StateError('Notification locale introuvable.'),
    );
  }

  Future<void> markAllRead() async {
    final page = await getNotifications();
    await _saveReadIds(page.items.map((item) => item.id).toSet());
  }

  Future<AppNotification?> _partnerApprovalNotification() async {
    final userId = _localUserId;
    if (userId == null || userId.isEmpty) return null;
    try {
      final response = await Supabase.instance.client
          .from('partner_applications')
          .select('id, status, updated_at, created_at')
          .eq('applicant_user_id', userId)
          .eq('status', 'approved')
          .order('updated_at', ascending: false)
          .limit(1);
      if (response.isEmpty) return null;
      final row = Map<String, dynamic>.from(response.first as Map);
      final id = 'partner-application-approved-${row['id']}';
      return AppNotification(
        id: id,
        userId: userId,
        type: 'partner_application_approved',
        title: 'Demande partenaire approuvee',
        message:
            'Votre espace partenaire est actif. Vous pouvez ajouter vos produits.',
        read: false,
        link: '/partner/home',
        createdAt: '${row['updated_at'] ?? row['created_at'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }

  String? get _localUserId {
    final token = _accessToken;
    if (token == null || !token.startsWith('local:')) return null;
    return token.substring('local:'.length);
  }

  Future<Set<String>> _readIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readKey);
    if (raw == null || raw.isEmpty) return <String>{};
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>{};
    return decoded.whereType<String>().toSet();
  }

  Future<void> _saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readKey, jsonEncode(ids.toList()));
  }
}
