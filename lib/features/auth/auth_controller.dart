import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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
      await prefs.remove(_sessionKey);
      final session = supabase.Supabase.instance.client.auth.currentSession;
      final authUser = session?.user;
      if (session != null && authUser != null) {
        _accessToken = session.accessToken;
        _user = await _loadProfile(authUser);
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
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final appRole = role.isDriver ? 'driver' : 'client';
      final response = await supabase.Supabase.instance.client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone': phone.trim(),
          'business_name': businessName.trim(),
          'role': appRole,
        },
      );
      final authUser = response.user;
      if (authUser == null) {
        throw AuthException(
          'Compte cree. Verifiez votre e-mail avant de vous connecter.',
        );
      }
      if (response.session == null) {
        throw AuthException(
          'Compte cree. Verifiez votre e-mail avant de vous connecter.',
        );
      }
      final profile = await _upsertProfile(
        id: authUser.id,
        email: normalizedEmail,
        firstName: firstName,
        lastName: lastName,
        role: appRole,
        phone: phone,
        businessName: businessName,
        emailVerified: authUser.emailConfirmedAt != null,
      );
      await _setSession(
        profile,
        accessToken: response.session?.accessToken,
      );
    } on AuthException {
      rethrow;
    } on supabase.AuthException catch (error) {
      throw AuthException(_friendlySupabaseAuthMessage(error.message));
    } on supabase.PostgrestException catch (error) {
      throw AuthException(_friendlyProfileMessage(error.message));
    } catch (_) {
      throw AuthException(
        'Impossible de creer le compte. Verifiez votre connexion.',
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final normalized = email.trim().toLowerCase();
      if (!normalized.contains('@')) {
        throw AuthException(
          'Connectez-vous avec votre e-mail. La connexion par telephone sera activee avec OTP.',
        );
      }
      final response =
          await supabase.Supabase.instance.client.auth.signInWithPassword(
        email: normalized,
        password: password,
      );
      final session = response.session;
      final authUser = response.user;
      if (session == null || authUser == null) {
        throw AuthException('Connexion impossible. Verifiez vos identifiants.');
      }
      await _setSession(
        await _loadProfile(authUser),
        accessToken: session.accessToken,
      );
    } on AuthException {
      rethrow;
    } on supabase.AuthException catch (error) {
      throw AuthException(_friendlySupabaseAuthMessage(error.message));
    } catch (_) {
      throw AuthException(
        'Impossible de se connecter. Verifiez votre connexion.',
      );
    }
  }

  Future<AuthUser> _upsertProfile({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
    required String phone,
    required String businessName,
    required bool emailVerified,
  }) async {
    final name = '$firstName $lastName'.trim();
    final rows = await supabase.Supabase.instance.client
        .from('users')
        .upsert({
          'id': id,
          'email': email,
          'name': name.isEmpty ? email : name,
          'role': role,
          'phone_number': phone.trim().isEmpty ? null : phone.trim(),
          'email_verified': emailVerified,
        }, onConflict: 'id')
        .select()
        .limit(1);
    return _userFromProfile(
      Map<String, dynamic>.from(rows.first as Map),
      businessName: businessName,
    );
  }

  Future<AuthUser> _loadProfile(supabase.User authUser) async {
    final rows = await supabase.Supabase.instance.client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .limit(1);
    if (rows.isEmpty) {
      return _upsertProfile(
        id: authUser.id,
        email: authUser.email ?? '',
        firstName: '${authUser.userMetadata?['first_name'] ?? ''}',
        lastName: '${authUser.userMetadata?['last_name'] ?? ''}',
        role: '${authUser.userMetadata?['role'] ?? 'client'}',
        phone: '${authUser.userMetadata?['phone'] ?? ''}',
        businessName: '${authUser.userMetadata?['business_name'] ?? ''}',
        emailVerified: authUser.emailConfirmedAt != null,
      );
    }
    return _userFromProfile(Map<String, dynamic>.from(rows.first as Map));
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
      await signOut();
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
    await _refreshCurrentProfile();
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
    final name = '${updated.firstName} ${updated.lastName}'.trim();
    await supabase.Supabase.instance.client.from('users').update({
      'name': name.isEmpty ? updated.email : name,
      'phone_number': updated.phone.trim().isEmpty ? null : updated.phone,
      'avatar_url': updated.avatarUrl,
    }).eq('id', updated.id);
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
      await signOut();
    } on supabase.AuthException catch (error) {
      throw AuthException(_friendlySupabaseAuthMessage(error.message));
    } catch (_) {
      throw AuthException(
        'Impossible de mettre a jour le mot de passe. Reessayez.',
      );
    }
  }

  Future<void> signOut() async {
    await supabase.Supabase.instance.client.auth.signOut();
    _user = null;
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> _setSession(AuthUser user, {String? accessToken}) async {
    _user = user;
    _accessToken = accessToken ??
        supabase.Supabase.instance.client.auth.currentSession?.accessToken;
    notifyListeners();
  }

  Future<void> _refreshCurrentProfile() async {
    final authUser = supabase.Supabase.instance.client.auth.currentUser;
    final session = supabase.Supabase.instance.client.auth.currentSession;
    if (authUser == null || session == null) return;
    await _setSession(
      await _loadProfile(authUser),
      accessToken: session.accessToken,
    );
  }

  AuthUser _userFromProfile(
    Map<String, dynamic> profile, {
    String businessName = '',
  }) {
    final name = '${profile['name'] ?? ''}'.trim();
    final parts =
        name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

    return AuthUser(
      id: '${profile['id'] ?? ''}',
      firstName: parts.isNotEmpty ? parts.first : '',
      lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
      email: '${profile['email'] ?? ''}',
      phone: '${profile['phone_number'] ?? ''}',
      role: AccountRoleX.fromId('${profile['role'] ?? 'client'}'),
      businessName: businessName,
      avatarUrl: profile['avatar_url'] as String?,
      emailVerified: profile['email_verified'] == true,
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
    if (lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('user_already_exists')) {
      return 'Un compte existe deja avec cet e-mail. Connectez-vous plutot.';
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

  String _friendlyProfileMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('row-level security') ||
        lower.contains('permission denied') ||
        lower.contains('403')) {
      return 'Compte cree, mais le profil NovaShop n\'a pas pu etre initialise. Connectez-vous, puis reessayez.';
    }
    return 'Compte cree, mais le profil NovaShop n\'a pas pu etre initialise. Reessayez la connexion.';
  }
}
