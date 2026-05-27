import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/partner_application.dart';
import 'repository_error.dart';

class PartnerApplicationRepository {
  PartnerApplicationRepository({String? accessToken})
      : _accessToken = accessToken;

  static const _localKey = 'novaishop.local.partner_applications';

  final String? _accessToken;

  Future<void> submit({
    required String whatsapp,
    required String productDescription,
    required List<PartnerApplicationImage> images,
    String? applicantUserId,
    String? applicantEmail,
  }) async {
    final userId = applicantUserId?.trim() ?? '';
    final existing = await getLatestForUser(userId);
    if (existing != null) {
      throw RepositoryException(
        'Une demande partenaire existe deja pour ce compte.',
      );
    }

    final payload = {
      'whatsapp': whatsapp.trim(),
      'product_description': productDescription.trim(),
      'product_images': images.map((image) => image.toJson()).toList(),
      'applicant_user_id': applicantUserId,
      'applicant_email': applicantEmail,
      'source': 'mobile_app',
      'status': 'new',
    };

    try {
      await Supabase.instance.client.from('partner_applications').insert(
            payload..removeWhere((_, value) => value == null),
          );
      await _saveLocal({...payload, 'synced': true});
    } catch (_) {
      await _saveLocal({...payload, 'synced': false});
      throw RepositoryException(
        'Demande sauvegardee localement. Reessayez quand la connexion revient.',
      );
    }
  }

  Future<Map<String, dynamic>?> getLatestForUser(String userId) async {
    if (userId.trim().isEmpty) return null;
    try {
      final response = await Supabase.instance.client
          .from('partner_applications')
          .select(
            'id, whatsapp, product_description, applicant_user_id, '
            'applicant_email, status, admin_notes, created_at, updated_at',
          )
          .eq('applicant_user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      if (response.isNotEmpty) {
        final latest = Map<String, dynamic>.from(response.first as Map);
        await _upsertLocal(latest);
        return latest;
      }
    } catch (_) {
      // Local session ids are used before Supabase Auth is wired end-to-end.
      // If remote status lookup is unavailable, the local snapshot keeps the
      // user from submitting duplicate applications on this device.
    }
    return getLatestLocalForUser(userId);
  }

  Future<Map<String, dynamic>?> getLatestLocalForUser(String userId) async {
    if (userId.trim().isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    final rows = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['applicant_user_id'] == userId)
        .toList();
    if (rows.isEmpty) return null;
    rows.sort(
      (a, b) => '${b['created_at'] ?? ''}'.compareTo(
        '${a['created_at'] ?? ''}',
      ),
    );
    return rows.first;
  }

  Future<void> _saveLocal(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    final current = raw == null || raw.isEmpty ? <dynamic>[] : jsonDecode(raw);
    final rows = current is List ? current : <dynamic>[];
    rows.add({
      ...payload,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'accessTokenType':
          _accessToken == null ? 'anonymous' : 'session_available',
    });
    await prefs.setString(_localKey, jsonEncode(rows));
  }

  Future<void> _upsertLocal(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    final current = raw == null || raw.isEmpty ? <dynamic>[] : jsonDecode(raw);
    final rows = current is List ? current : <dynamic>[];
    final index = rows.indexWhere((item) {
      if (item is! Map) return false;
      final id = item['id'];
      return id != null && id == payload['id'];
    });
    final merged = {
      ...payload,
      'synced': true,
      'accessTokenType':
          _accessToken == null ? 'anonymous' : 'session_available',
    };
    if (index == -1) {
      rows.add(merged);
    } else {
      rows[index] = {
        ...Map<String, dynamic>.from(rows[index] as Map),
        ...merged,
      };
    }
    await prefs.setString(_localKey, jsonEncode(rows));
  }
}
