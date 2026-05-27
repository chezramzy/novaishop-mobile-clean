import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/address.dart';

/// Local address book backed by `shared_preferences`. There is no addresses
/// API — delivery addresses live only on the device.
///
/// Not token-dependent; register it as a plain `Provider`.
class AddressRepository {
  AddressRepository({SharedPreferences? prefs}) : _prefs = prefs;

  static const _storeKey = 'novaishop.addresses';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// All saved addresses, with the default address first.
  Future<List<Address>> getAddresses() async {
    final store = await _store;
    final raw = store.getString(_storeKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final addresses = decoded
          .whereType<Map>()
          .map((item) => Address.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      addresses.sort((a, b) {
        if (a.isDefault == b.isDefault) return 0;
        return a.isDefault ? -1 : 1;
      });
      return addresses;
    } catch (_) {
      return const [];
    }
  }

  /// Adds [address]. When it is the first one, it becomes the default.
  Future<List<Address>> addAddress(Address address) async {
    final current = await getAddresses();
    final isFirst = current.isEmpty;
    final toAdd = address.copyWith(isDefault: address.isDefault || isFirst);
    final next = [...current, toAdd];
    return _persistEnsuringSingleDefault(next, toAdd.id);
  }

  /// Updates an existing address by id.
  Future<List<Address>> updateAddress(Address address) async {
    final current = await getAddresses();
    final next =
        current.map((item) => item.id == address.id ? address : item).toList();
    return _persistEnsuringSingleDefault(
      next,
      address.isDefault ? address.id : null,
    );
  }

  /// Removes an address by id. If it was the default, the first remaining
  /// address becomes the new default.
  Future<List<Address>> removeAddress(String id) async {
    final current = await getAddresses();
    final next = current.where((item) => item.id != id).toList();
    if (next.isNotEmpty && !next.any((item) => item.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    await _save(next);
    return getAddresses();
  }

  /// Marks the address with [id] as the default.
  Future<List<Address>> setDefault(String id) async {
    final current = await getAddresses();
    return _persistEnsuringSingleDefault(current, id);
  }

  /// The current default address, or `null` when the book is empty.
  Future<Address?> getDefault() async {
    final addresses = await getAddresses();
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (item) => item.isDefault,
      orElse: () => addresses.first,
    );
  }

  Future<List<Address>> _persistEnsuringSingleDefault(
    List<Address> addresses,
    String? defaultId,
  ) async {
    final next = addresses
        .map((item) => item.copyWith(isDefault: item.id == defaultId))
        .toList();
    if (defaultId == null && next.isNotEmpty && !next.any((a) => a.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    await _save(next);
    return getAddresses();
  }

  Future<void> _save(List<Address> addresses) async {
    final store = await _store;
    await store.setString(
      _storeKey,
      jsonEncode([for (final a in addresses) a.toJson()]),
    );
  }
}
