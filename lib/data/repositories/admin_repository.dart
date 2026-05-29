import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import '../models/partner_application.dart';
import 'repository_error.dart';

class AdminRepository {
  const AdminRepository();

  Future<List<PartnerApplication>> getPartnerApplications({
    String? status,
  }) async {
    try {
      var request =
          Supabase.instance.client.from('partner_applications').select();
      if (status != null && status.isNotEmpty) {
        request = request.eq('status', status);
      }
      final rows = await request.order('created_at', ascending: false);
      return rows
          .whereType<Map>()
          .map((row) => PartnerApplication.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<PartnerApplication> markApplicationReviewing(String id) async {
    try {
      final rows = await Supabase.instance.client
          .from('partner_applications')
          .update({'status': 'reviewing'})
          .eq('id', id)
          .select()
          .limit(1);
      return PartnerApplication.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<PartnerApplication> reviewPartnerApplication(
    String id, {
    required bool approve,
    String? note,
  }) async {
    try {
      final row = await Supabase.instance.client
          .rpc('review_partner_application', params: {
        'application_id': id,
        'approve': approve,
        'note': note,
      });
      return PartnerApplication.fromJson(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

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
