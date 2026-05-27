import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import 'repository_error.dart';

class AdminRepository {
  const AdminRepository();

  Future<List<Listing>> getPendingListings() async {
    try {
      final rows = await Supabase.instance.client
          .from('listings')
          .select()
          .eq('status', 'pending_review')
          .order('created_at', ascending: false);
      return rows
          .whereType<Map>()
          .map((row) => Listing.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Listing> approveListing(String listingId) async {
    try {
      final rows = await Supabase.instance.client
          .from('listings')
          .update({
            'status': 'published',
            'updated_at': DateTime.now().toUtc().toIso8601String()
          })
          .eq('id', listingId)
          .select()
          .limit(1);
      return Listing.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Listing> rejectListing(String listingId) async {
    try {
      final rows = await Supabase.instance.client
          .from('listings')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toUtc().toIso8601String()
          })
          .eq('id', listingId)
          .select()
          .limit(1);
      return Listing.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }
}
