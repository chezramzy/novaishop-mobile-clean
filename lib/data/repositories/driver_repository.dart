import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/delivery.dart';
import '../models/delivery_driver.dart';
import 'repository_error.dart';

class DriverRepository {
  DriverRepository({required String? accessToken}) : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSession =>
      Supabase.instance.client.auth.currentSession != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession(String message) {
    if (!_hasSession) throw RepositoryException(message);
  }

  Future<DeliveryDriver> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String vehicleType,
    String? licensePlate,
  }) async {
    _requireSession('Reconnectez-vous pour creer un profil livreur.');
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw RepositoryException('Session introuvable. Reconnectez-vous.');
    }
    try {
      final existing = await _currentDriverOrNull();
      if (existing != null) return existing;
      final rows = await Supabase.instance.client
          .from('delivery_drivers')
          .insert({
            'user_id': user.id,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'phone': phone.trim(),
            'vehicle_type': vehicleType,
            if (licensePlate != null && licensePlate.trim().isNotEmpty)
              'license_plate': licensePlate.trim(),
            'status': 'offline',
          })
          .select()
          .limit(1);
      return DeliveryDriver.fromJson(_driverJson(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<DriverDashboardSummary?> getDashboard() async {
    _requireSession('Reconnectez-vous pour voir votre espace livreur.');
    try {
      final driver = await _currentDriverOrNull();
      if (driver == null) return null;
      final activeDeliveries = await getMyDeliveries();
      final completedToday = activeDeliveries
          .where((delivery) => delivery.status == 'delivered')
          .length;
      final todayEarnings = activeDeliveries
          .where((delivery) => delivery.status == 'delivered')
          .fold<double>(0, (sum, item) => sum + item.driverEarning);
      return DriverDashboardSummary(
        driver: driver,
        activeDeliveries:
            activeDeliveries.where((delivery) => delivery.isActive).toList(),
        todayStats: DriverTodayStats(
          completed: completedToday,
          earnings: todayEarnings,
          avgRating: driver.rating,
        ),
        weeklyEarnings: const [],
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Delivery>> getMyDeliveries({String? status}) async {
    _requireSession('Reconnectez-vous pour voir vos livraisons.');
    try {
      final driver = await _currentDriverOrNull();
      if (driver == null) return const [];
      var request = Supabase.instance.client
          .from('deliveries')
          .select()
          .eq('driver_id', driver.id);
      if (status != null && status.isNotEmpty) {
        request = request.eq('status', status);
      }
      final rows = await request.order('created_at', ascending: false);
      return rows
          .whereType<Map>()
          .map((row) => Delivery.fromJson(_deliveryJson(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<DriverEarnings> getEarnings() async {
    _requireSession('Reconnectez-vous pour voir vos gains.');
    try {
      final deliveries = await getMyDeliveries(status: 'delivered');
      final total = deliveries.fold<double>(
        0,
        (sum, delivery) => sum + delivery.driverEarning,
      );
      return DriverEarnings(
        totalEarnings: total,
        weeklyEarnings: total,
        monthlyEarnings: total,
        pendingPayout: total,
        earningsHistory: deliveries
            .map(
              (delivery) => EarningsPoint(
                date: delivery.actualDeliveryTime ?? delivery.updatedAt,
                amount: delivery.driverEarning,
                deliveryCount: 1,
              ),
            )
            .toList(),
        recentPayouts: const [],
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Delivery> getDelivery(String deliveryId) async {
    _requireSession('Reconnectez-vous pour voir cette livraison.');
    try {
      final driver = await _currentDriverOrNull();
      if (driver == null) {
        throw RepositoryException('Profil livreur introuvable.');
      }
      final rows = await Supabase.instance.client
          .from('deliveries')
          .select()
          .eq('id', deliveryId)
          .eq('driver_id', driver.id)
          .limit(1);
      if (rows.isEmpty) {
        throw RepositoryException('Livraison introuvable ou non autorisee.');
      }
      return Delivery.fromJson(_deliveryJson(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Delivery> updateDeliveryStatus(
    String deliveryId, {
    required String status,
    String? notes,
  }) async {
    _requireSession('Reconnectez-vous pour mettre a jour la livraison.');
    try {
      final driver = await _currentDriverOrNull();
      if (driver == null) {
        throw RepositoryException('Profil livreur introuvable.');
      }
      final rows = await Supabase.instance.client
          .from('deliveries')
          .update({
            'status': status,
            if (status == 'delivered')
              'actual_delivery_time': DateTime.now().toUtc().toIso8601String(),
            if (notes != null) 'notes': notes,
          })
          .eq('id', deliveryId)
          .eq('driver_id', driver.id)
          .select()
          .limit(1);
      if (rows.isEmpty) {
        throw RepositoryException('Livraison introuvable ou non autorisee.');
      }
      return Delivery.fromJson(_deliveryJson(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<DeliveryDriver?> _currentDriverOrNull() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final rows = await Supabase.instance.client
        .from('delivery_drivers')
        .select()
        .eq('user_id', user.id)
        .limit(1);
    if (rows.isEmpty) return null;
    return DeliveryDriver.fromJson(_driverJson(rows.first as Map));
  }

  Map<String, dynamic> _driverJson(Map row) {
    final json = Map<String, dynamic>.from(row);
    return {
      ...json,
      'userId': json['user_id'],
      'firstName': json['first_name'],
      'lastName': json['last_name'],
      'vehicleType': json['vehicle_type'],
      'licensePlate': json['license_plate'],
      'totalDeliveries': json['total_deliveries'],
      'createdAt': json['created_at'],
    };
  }

  Map<String, dynamic> _deliveryJson(Map row) {
    final json = Map<String, dynamic>.from(row);
    return {
      ...json,
      'orderId': json['order_id'],
      'driverId': json['driver_id'],
      'pickupAddress': json['pickup_address'],
      'pickupCity': json['pickup_city'],
      'deliveryAddress': json['delivery_address'],
      'deliveryCity': json['delivery_city'],
      'customerName': json['customer_name'],
      'customerPhone': json['customer_phone'],
      'estimatedDeliveryTime': json['estimated_delivery_time'],
      'actualDeliveryTime': json['actual_delivery_time'],
      'deliveryFee': json['delivery_fee'],
      'driverEarning': json['driver_earning'],
      'trackingNumber': json['tracking_number'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    };
  }
}
