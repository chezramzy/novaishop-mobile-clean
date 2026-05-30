import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/category.dart';
import '../models/conversation.dart';
import '../models/listing.dart';
import '../models/partner_application.dart';
import '../models/user.dart' as app_user;
import '../models/vendor_profile.dart';
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
      final applications = <PartnerApplication>[];
      for (final row in rows.whereType<Map>()) {
        final data = await _withSignedApplicationImages(
          Map<String, dynamic>.from(row),
        );
        applications.add(PartnerApplication.fromJson(data));
      }
      return applications;
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Map<String, dynamic>> _withSignedApplicationImages(
    Map<String, dynamic> row,
  ) async {
    final rawImages = row['product_images'];
    if (rawImages is! List) return row;
    final images = <Map<String, dynamic>>[];
    for (final raw in rawImages.whereType<Map>()) {
      final image = Map<String, dynamic>.from(raw);
      final bucket = '${image['bucket'] ?? ''}';
      final objectKey = '${image['objectKey'] ?? image['object_key'] ?? ''}';
      if (bucket == 'private-kyc' && objectKey.isNotEmpty) {
        image['publicUrl'] = await Supabase.instance.client.storage
            .from('private-kyc')
            .createSignedUrl(objectKey, 60 * 30);
      }
      images.add(image);
    }
    return {
      ...row,
      'product_images': images,
    };
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
      final row = await Supabase.instance.client.rpc(
        'review_listing',
        params: {
          'p_listing_id': listingId,
          'p_approve': true,
          'p_note': null,
        },
      );
      return Listing.fromJson(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Listing> rejectListing(String listingId, {String? note}) async {
    try {
      final row = await Supabase.instance.client.rpc(
        'review_listing',
        params: {
          'p_listing_id': listingId,
          'p_approve': false,
          'p_note': note,
        },
      );
      return Listing.fromJson(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Conversation>> getOrderConversations({int limit = 30}) async {
    try {
      final rows = await Supabase.instance.client
          .from('conversations')
          .select()
          .order('updated_at', ascending: false)
          .limit(limit);
      return rows
          .whereType<Map>()
          .map((row) => Conversation.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final rows = await Supabase.instance.client
          .from('categories')
          .select()
          .order('parent_id', nullsFirst: true)
          .order('sort_order')
          .order('name');
      return rows
          .whereType<Map>()
          .map((row) => Category.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Category> upsertCategory({
    required String name,
    required String slug,
    String type = 'product',
    String description = '',
    String? parentId,
    bool active = true,
    int sortOrder = 0,
    String formTemplate = 'standard',
    String? id,
  }) async {
    try {
      final categoryId = (id == null || id.isEmpty) ? slug.trim() : id;
      final rows = await Supabase.instance.client
          .from('categories')
          .upsert({
            'id': categoryId,
            'name': name.trim(),
            'slug': slug.trim(),
            'type': type.trim().isEmpty ? 'product' : type.trim(),
            'description': description.trim(),
            'parent_id':
                parentId?.trim().isEmpty ?? true ? null : parentId!.trim(),
            'active': active,
            'sort_order': sortOrder,
            'form_template':
                formTemplate.trim().isEmpty ? 'standard' : formTemplate.trim(),
          })
          .select()
          .limit(1);
      return Category.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Category> setCategoryActive(Category category, bool active) async {
    try {
      final rows = await Supabase.instance.client
          .from('categories')
          .update({'active': active})
          .eq('id', category.id)
          .select()
          .limit(1);
      return Category.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<app_user.User>> getUsers({int limit = 50}) async {
    try {
      final rows = await Supabase.instance.client
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows
          .whereType<Map>()
          .map((row) => app_user.User.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<VendorProfile>> getVendors({int limit = 50}) async {
    try {
      final rows = await Supabase.instance.client
          .from('vendors')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows
          .whereType<Map>()
          .map((row) => VendorProfile.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows
          .whereType<Map>()
          .map(
              (row) => AppNotification.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Map<String, dynamic>>> getAuditEvents({int limit = 40}) async {
    try {
      final rows = await Supabase.instance.client
          .from('audit_events')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }
}
