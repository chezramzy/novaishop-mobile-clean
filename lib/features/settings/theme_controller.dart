import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contrôle le mode d'affichage (Clair / Sombre / Système) de NovAiShop.
///
/// La préférence est persistée via `shared_preferences` sous une clé
/// réservée et restaurée au démarrage de l'application.
class ThemeController extends ChangeNotifier {
  /// Clé de stockage de la préférence de thème.
  static const _storageKey = 'novaishop.settings.themeMode';

  ThemeMode _mode = ThemeMode.system;

  /// Le mode de thème actuellement sélectionné.
  ThemeMode get mode => _mode;

  /// Libellé français du mode courant, pour l'affichage dans les réglages.
  String get label => labelFor(_mode);

  /// Libellé français correspondant à [mode].
  static String labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  /// Restaure la préférence enregistrée. À appeler au démarrage.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    _mode = _decode(stored);
    notifyListeners();
  }

  /// Met à jour le mode et le persiste.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _encode(mode));
  }

  static ThemeMode _decode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
