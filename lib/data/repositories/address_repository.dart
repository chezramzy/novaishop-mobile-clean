import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/address.dart';
import 'repository_error.dart';

class AddressRepository {
  AddressRepository();

  Future<List<Address>> getAddresses() async {
    _requireUser();
    try {
      final rows = await Supabase.instance.client
          .from('addresses')
          .select()
          .eq('user_id', _userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      return rows
          .whereType<Map>()
          .map((row) => _fromRow(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Address>> addAddress(Address address) async {
    _requireUser();
    try {
      final current = await getAddresses();
      final addressToSave =
          current.isEmpty ? address.copyWith(isDefault: true) : address;
      if (addressToSave.isDefault) {
        await _clearDefault();
      }
      await Supabase.instance.client
          .from('addresses')
          .insert(_toRow(addressToSave));
      return getAddresses();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Address>> updateAddress(Address address) async {
    _requireUser();
    try {
      if (address.isDefault) {
        await _clearDefault();
      }
      await Supabase.instance.client
          .from('addresses')
          .update(_toRow(address, includeUserId: false))
          .eq('id', address.id)
          .eq('user_id', _userId);
      return getAddresses();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Address>> removeAddress(String id) async {
    _requireUser();
    try {
      await Supabase.instance.client
          .from('addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
      final remaining = await getAddresses();
      if (remaining.isNotEmpty && !remaining.any((item) => item.isDefault)) {
        return setDefault(remaining.first.id);
      }
      return remaining;
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Address>> setDefault(String id) async {
    _requireUser();
    try {
      await _clearDefault();
      await Supabase.instance.client
          .from('addresses')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', _userId);
      return getAddresses();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Address?> getDefault() async {
    final addresses = await getAddresses();
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  Future<void> _clearDefault() {
    return Supabase.instance.client
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', _userId)
        .eq('is_default', true);
  }

  Map<String, dynamic> _toRow(Address address, {bool includeUserId = true}) {
    return {
      'id': address.id,
      if (includeUserId) 'user_id': _userId,
      'label': address.label,
      'line': address.line,
      'city': address.city,
      'country': address.country,
      'phone': address.phone,
      'is_default': address.isDefault,
      'map_image_url': address.mapImageUrl,
    };
  }

  Address _fromRow(Map<String, dynamic> row) {
    return Address.fromJson({
      'id': row['id'],
      'label': row['label'],
      'line': row['line'],
      'city': row['city'],
      'country': row['country'],
      'phone': row['phone'],
      'isDefault': row['is_default'],
      'mapImageUrl': row['map_image_url'],
    });
  }

  void _requireUser() {
    if (Supabase.instance.client.auth.currentUser == null) {
      throw RepositoryException('Reconnectez-vous pour gerer vos adresses.');
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
