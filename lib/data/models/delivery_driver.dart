import 'delivery.dart';
import 'json_utils.dart';

/// A delivery driver's profile (`DeliveryDriver` interface).
class DeliveryDriver {
  const DeliveryDriver({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.vehicleType,
    required this.status,
    required this.rating,
    required this.totalDeliveries,
    required this.createdAt,
    this.licensePlate,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;

  /// One of: `moto`, `car`, `bicycle`, `van`.
  final String vehicleType;
  final String? licensePlate;

  /// One of: `available`, `busy`, `offline`.
  final String status;
  final double rating;
  final int totalDeliveries;
  final String createdAt;

  String get fullName => '$firstName $lastName'.trim();

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) {
    return DeliveryDriver(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      firstName: Json.str(json['firstName']),
      lastName: Json.str(json['lastName']),
      phone: Json.str(json['phone']),
      vehicleType: Json.str(json['vehicleType'], 'moto'),
      licensePlate: Json.strOrNull(json['licensePlate']),
      status: Json.str(json['status'], 'offline'),
      rating: Json.dbl(json['rating']),
      totalDeliveries: Json.integer(json['totalDeliveries']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}

/// A driver's daily statistics block.
class DriverTodayStats {
  const DriverTodayStats({
    required this.completed,
    required this.earnings,
    required this.avgRating,
  });

  final int completed;
  final double earnings;
  final double avgRating;

  factory DriverTodayStats.fromJson(Map<String, dynamic> json) {
    return DriverTodayStats(
      completed: Json.integer(json['completed']),
      earnings: Json.dbl(json['earnings']),
      avgRating: Json.dbl(json['avgRating']),
    );
  }
}

/// A (date, amount) earnings point with a delivery count.
class EarningsPoint {
  const EarningsPoint({
    required this.date,
    required this.amount,
    this.deliveryCount = 0,
  });

  final String date;
  final double amount;
  final int deliveryCount;

  factory EarningsPoint.fromJson(Map<String, dynamic> json) {
    return EarningsPoint(
      date: Json.str(json['date']),
      amount: Json.dbl(json['amount']),
      deliveryCount: Json.integer(json['deliveryCount']),
    );
  }
}

/// A recorded payout to a driver.
class DriverPayout {
  const DriverPayout({
    required this.id,
    required this.amount,
    required this.date,
    required this.status,
  });

  final String id;
  final double amount;
  final String date;
  final String status;

  factory DriverPayout.fromJson(Map<String, dynamic> json) {
    return DriverPayout(
      id: Json.str(json['id']),
      amount: Json.dbl(json['amount']),
      date: Json.str(json['date']),
      status: Json.str(json['status']),
    );
  }
}

/// The driver dashboard snapshot (`DriverDashboardSummary` interface).
class DriverDashboardSummary {
  const DriverDashboardSummary({
    required this.driver,
    required this.activeDeliveries,
    required this.todayStats,
    required this.weeklyEarnings,
  });

  final DeliveryDriver driver;
  final List<Delivery> activeDeliveries;
  final DriverTodayStats todayStats;
  final List<EarningsPoint> weeklyEarnings;

  factory DriverDashboardSummary.fromJson(Map<String, dynamic> json) {
    return DriverDashboardSummary(
      driver: DeliveryDriver.fromJson(Json.obj(json['driver'])),
      activeDeliveries: Json.list(json['activeDeliveries'], Delivery.fromJson),
      todayStats: DriverTodayStats.fromJson(Json.obj(json['todayStats'])),
      weeklyEarnings: Json.list(json['weeklyEarnings'], EarningsPoint.fromJson),
    );
  }
}

/// A driver's earnings breakdown (`DriverEarnings` interface).
class DriverEarnings {
  const DriverEarnings({
    required this.totalEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.pendingPayout,
    required this.earningsHistory,
    required this.recentPayouts,
  });

  final double totalEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double pendingPayout;
  final List<EarningsPoint> earningsHistory;
  final List<DriverPayout> recentPayouts;

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      totalEarnings: Json.dbl(json['totalEarnings']),
      weeklyEarnings: Json.dbl(json['weeklyEarnings']),
      monthlyEarnings: Json.dbl(json['monthlyEarnings']),
      pendingPayout: Json.dbl(json['pendingPayout']),
      earningsHistory:
          Json.list(json['earningsHistory'], EarningsPoint.fromJson),
      recentPayouts: Json.list(json['recentPayouts'], DriverPayout.fromJson),
    );
  }
}
