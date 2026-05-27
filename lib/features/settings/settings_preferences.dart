import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales simples du module Réglages (WS6), persistées via
/// `shared_preferences` sous des clés réservées à ce module.
class SettingsPreferences {
  const SettingsPreferences._();

  static const _prefix = 'novaishop.ws6.settings.';
  static const _orderUpdatesKey = '${_prefix}notif.orders';
  static const _promotionsKey = '${_prefix}notif.promotions';
  static const _deliveryKey = '${_prefix}notif.delivery';
  static const _emailKey = '${_prefix}notif.email';
  static const _soundKey = '${_prefix}notif.sound';

  /// Charge l'ensemble des préférences avec leurs valeurs par défaut.
  static Future<SettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      orderUpdates: prefs.getBool(_orderUpdatesKey) ?? true,
      promotions: prefs.getBool(_promotionsKey) ?? true,
      deliveryUpdates: prefs.getBool(_deliveryKey) ?? true,
      emailDigest: prefs.getBool(_emailKey) ?? false,
      sound: prefs.getBool(_soundKey) ?? true,
    );
  }

  static Future<void> setOrderUpdates(bool value) =>
      _set(_orderUpdatesKey, value);
  static Future<void> setPromotions(bool value) => _set(_promotionsKey, value);
  static Future<void> setDeliveryUpdates(bool value) =>
      _set(_deliveryKey, value);
  static Future<void> setEmailDigest(bool value) => _set(_emailKey, value);
  static Future<void> setSound(bool value) => _set(_soundKey, value);

  static Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

/// Instantané immuable des préférences de réglages.
class SettingsState {
  const SettingsState({
    required this.orderUpdates,
    required this.promotions,
    required this.deliveryUpdates,
    required this.emailDigest,
    required this.sound,
  });

  final bool orderUpdates;
  final bool promotions;
  final bool deliveryUpdates;
  final bool emailDigest;
  final bool sound;

  SettingsState copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? deliveryUpdates,
    bool? emailDigest,
    bool? sound,
  }) {
    return SettingsState(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      deliveryUpdates: deliveryUpdates ?? this.deliveryUpdates,
      emailDigest: emailDigest ?? this.emailDigest,
      sound: sound ?? this.sound,
    );
  }
}
