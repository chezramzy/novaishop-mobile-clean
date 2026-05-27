import '../models/delivery.dart';
import '../models/delivery_driver.dart';
import 'repository_error.dart';

class DriverRepository {
  DriverRepository({required String? accessToken});

  Future<DeliveryDriver> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String vehicleType,
    String? licensePlate,
  }) async {
    return DeliveryDriver.fromJson({
      'id': 'driver-${DateTime.now().microsecondsSinceEpoch}',
      'userId': 'local',
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'vehicleType': vehicleType,
      'licensePlate': licensePlate,
      'status': 'offline',
      'rating': 0,
      'totalDeliveries': 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<DriverDashboardSummary?> getDashboard() async => null;

  Future<List<Delivery>> getMyDeliveries({String? status}) async => const [];

  Future<DriverEarnings> getEarnings() async {
    return const DriverEarnings(
      totalEarnings: 0,
      weeklyEarnings: 0,
      monthlyEarnings: 0,
      pendingPayout: 0,
      earningsHistory: [],
      recentPayouts: [],
    );
  }

  Future<Delivery> getDelivery(String deliveryId) async {
    throw RepositoryException('Livraison locale introuvable.');
  }

  Future<Delivery> updateDeliveryStatus(
    String deliveryId, {
    required String status,
    String? notes,
  }) async {
    throw RepositoryException('Livraison locale introuvable.');
  }
}
