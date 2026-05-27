import 'package:flutter/foundation.dart';

import '../../data/models/auth_user.dart';

/// Lightweight, app-wide view of the current session.
///
/// Exposes only what shared infrastructure needs — the Supabase access
/// token and the active [AccountRole] — without depending on the full
/// `AuthController`. The composition root keeps it in sync with auth state.
class SessionScope extends ChangeNotifier {
  SessionScope({String? accessToken, AccountRole? role})
      : _accessToken = accessToken,
        _role = role;

  String? _accessToken;
  AccountRole? _role;

  /// The Supabase bearer token, or `null` when signed out.
  String? get accessToken => _accessToken;

  /// The active account role, or `null` when signed out.
  AccountRole? get role => _role;

  /// Whether a usable token is present.
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  bool get isBuyer => _role?.isBuyer ?? false;
  bool get isSeller => _role?.isSeller ?? false;
  bool get isDriver => _role?.isDriver ?? false;

  /// Updates the session and notifies listeners only when something changed.
  void update({String? accessToken, AccountRole? role}) {
    if (_accessToken == accessToken && _role == role) return;
    _accessToken = accessToken;
    _role = role;
    notifyListeners();
  }

  /// Clears the session (sign-out).
  void clear() => update(accessToken: null, role: null);
}
