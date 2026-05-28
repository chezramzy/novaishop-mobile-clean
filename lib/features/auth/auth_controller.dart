import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/local_backend/local_backend.dart';
import '../../data/models/auth_user.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthController extends ChangeNotifier {
  AuthController();

  static const _sessionKey = 'novaishop.auth.session';
  static const _passwordResetRedirect = 'novaishop://reset-password';

  AuthUser? _user;
  String? _accessToken;
  bool _initialized = false;
  bool _busy = false;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get initialized => _initialized;
  bool get isBusy => _busy;
  bool get isAuthenticated => _user != null;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        if (decoded.containsKey('user')) {
          _user = AuthUser.fromJson(
            Map<String, dynamic>.from(decoded['user'] as Map),
          );
          _accessToken = decoded['accessToken'] as String?;
          if (_accessToken != null && !_accessToken!.startsWith('local:')) {
            await prefs.remove(_sessionKey);
            _user = null;
            _accessToken = null;
          }
        } else {
          _user = AuthUser.fromJson(decoded);
        }
      }
    } catch (_) {
      _user = null;
      _accessToken = null;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required AccountRole role,
    String phone = '',
    String businessName = '',
  }) async {
    final response = await _authRequest(
      () => LocalBackend.instance.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        role: role,
        phone: phone,
        businessName: businessName,
      ),
    );

    await _setSession(
      _userFromAuthPayload(
        response,
        fallbackFirstName: firstName.trim(),
        fallbackLastName: lastName.trim(),
        fallbackRole: role,
      ),
      accessToken: response['accessToken'] as String?,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _authRequest(
      () => LocalBackend.instance.signIn(email: email, password: password),
    );

    await _setSession(
      _userFromAuthPayload(response),
      accessToken: response['accessToken'] as String?,
    );
  }

  Future<void> signInWithProvider(String provider) async {
    throw AuthException('Connexion $provider indisponible pour le moment.');
  }

  Future<void> sendPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw AuthException('Saisissez une adresse e-mail valide.');
    }

    try {
      await supabase.Supabase.instance.client.auth.resetPasswordForEmail(
        normalized,
        redirectTo: _passwordResetRedirect,
      );
    } on supabase.AuthException catch (error) {
      throw AuthException(_friendlySupabaseAuthMessage(error.message));
    } catch (_) {
      throw AuthException(
        'Impossible de contacter Supabase. Verifiez votre connexion.',
      );
    }
  }

  Future<void> updateRecoveredPassword({required String newPassword}) async {
    try {
      final auth = supabase.Supabase.instance.client.auth;
      if (auth.currentSession == null) {
        throw AuthException(
          'Lien de reinitialisation invalide ou expire. Demandez un nouveau lien.',
        );
      }

      await auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
      await auth.signOut();
    } on AuthException {
      rethrow;
    } on supabase.AuthException catch (error) {
      throw AuthException(_friendlySupabaseAuthMessage(error.message));
    } catch (_) {
      throw AuthException(
        'Impossible de mettre a jour le mot de passe. Reessayez.',
      );
    }
  }

  Future<void> confirmEmailVerification() async {
    final current = _user;
    if (current == null) return;
    await _setSession(
      current.copyWith(emailVerified: true),
      accessToken: _accessToken,
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? businessName,
    String? avatarUrl,
  }) async {
    final current = _user;
    if (current == null) return;

    final updated = current.copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      businessName: businessName?.trim(),
      avatarUrl: avatarUrl,
    );
    await LocalBackend.instance.updateUser(updated);
    await _setSession(updated, accessToken: _accessToken);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = _user;
    if (current == null || current.email.trim().isEmpty) {
      throw AuthException('Reconnectez-vous pour modifier le mot de passe.');
    }

    try {
      final auth = supabase.Supabase.instance.client.auth;
      await auth.signInWithPassword(
        email: current.email.trim().toLowerCase(),
        password: currentPassword,
      );
      await auth.updateUser(supabase.UserAttributes(password: newPassword));
      await auth.signOut();
    } on supabase.AuthException catch (error) {
      throw AuthException(_friendlySupabaseAuthMessage(error.message));
    } catch (_) {
      throw AuthException(
        'Impossible de mettre a jour le mot de passe. Reessayez.',
      );
    }
  }

  Future<void> signOut() async {
    _user = null;
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> _setSession(AuthUser user, {String? accessToken}) async {
    _user = user;
    _accessToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'user': user.toJson(),
        'accessToken': accessToken,
      }),
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> _authRequest(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    try {
      return await action();
    } on LocalBackendException catch (error) {
      throw AuthException(error.message);
    }
  }

  AuthUser _userFromAuthPayload(
    Map<String, dynamic> payload, {
    String fallbackFirstName = '',
    String fallbackLastName = '',
    AccountRole fallbackRole = AccountRole.individualBuyer,
  }) {
    final user = Map<String, dynamic>.from(payload['user'] as Map);
    final name = (user['name'] as String? ?? '').trim();
    final parts =
        name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final apiRole = AccountRoleX.fromId(user['role'] as String?);
    final role = (user['role'] as String?) == null ? fallbackRole : apiRole;

    return AuthUser(
      id: user['id'] as String? ?? '',
      firstName: fallbackFirstName.isNotEmpty
          ? fallbackFirstName
          : (user['firstName'] as String? ?? '').isNotEmpty
              ? user['firstName'] as String
              : parts.isNotEmpty
                  ? parts.first
                  : '',
      lastName: fallbackLastName.isNotEmpty
          ? fallbackLastName
          : (user['lastName'] as String? ?? '').isNotEmpty
              ? user['lastName'] as String
              : parts.length > 1
                  ? parts.skip(1).join(' ')
                  : '',
      email: user['email'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
      role: role,
      businessName: user['businessName'] as String? ?? '',
      emailVerified: true,
    );
  }

  void setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  String _friendlySupabaseAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'Mot de passe actuel incorrect.';
    }
    if (lower.contains('expired') || lower.contains('invalid')) {
      return 'Lien de reinitialisation invalide ou expire.';
    }
    if (lower.contains('password')) {
      return 'Le mot de passe ne respecte pas les regles de securite.';
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Trop de tentatives. Patientez avant de reessayer.';
    }
    return 'Operation impossible pour le moment. Reessayez.';
  }
}
