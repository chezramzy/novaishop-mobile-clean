import 'json_utils.dart';

/// A single (date, amount) point in a time series.
class TimeSeriesPoint {
  const TimeSeriesPoint({required this.date, required this.amount});

  final String date;
  final double amount;

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesPoint(
      date: Json.str(json['date']),
      amount: Json.dbl(json['amount']),
    );
  }
}

/// A best-selling listing entry within [SellerAnalytics].
class BestSellerStat {
  const BestSellerStat({
    required this.listingId,
    required this.title,
    required this.unitsSold,
    required this.revenue,
  });

  final String listingId;
  final String title;
  final int unitsSold;
  final double revenue;

  factory BestSellerStat.fromJson(Map<String, dynamic> json) {
    return BestSellerStat(
      listingId: Json.str(json['listingId']),
      title: Json.str(json['title']),
      unitsSold: Json.integer(json['unitsSold']),
      revenue: Json.dbl(json['revenue']),
    );
  }
}

/// A stock-level entry within [SellerAnalytics].
class StockLevelStat {
  const StockLevelStat({
    required this.listingId,
    required this.title,
    required this.inventory,
    required this.status,
  });

  final String listingId;
  final String title;
  final int inventory;

  /// `ok`, `low` or `out`.
  final String status;

  factory StockLevelStat.fromJson(Map<String, dynamic> json) {
    return StockLevelStat(
      listingId: Json.str(json['listingId']),
      title: Json.str(json['title']),
      inventory: Json.integer(json['inventory']),
      status: Json.str(json['status'], 'ok'),
    );
  }
}

/// A (status, count) pair for an order-status distribution chart.
class StatusCount {
  const StatusCount({required this.status, required this.count});

  final String status;
  final int count;

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      status: Json.str(json['status']),
      count: Json.integer(json['count']),
    );
  }
}

/// Seller analytics (`SellerAnalytics` interface), returned by
/// `GET /v1/vendors/me/analytics`.
class SellerAnalytics {
  const SellerAnalytics({
    required this.revenueTimeSeries,
    required this.bestSellers,
    required this.stockLevels,
    required this.orderStatusDistribution,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  final List<TimeSeriesPoint> revenueTimeSeries;
  final List<BestSellerStat> bestSellers;
  final List<StockLevelStat> stockLevels;
  final List<StatusCount> orderStatusDistribution;
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;

  factory SellerAnalytics.fromJson(Map<String, dynamic> json) {
    return SellerAnalytics(
      revenueTimeSeries:
          Json.list(json['revenueTimeSeries'], TimeSeriesPoint.fromJson),
      bestSellers: Json.list(json['bestSellers'], BestSellerStat.fromJson),
      stockLevels: Json.list(json['stockLevels'], StockLevelStat.fromJson),
      orderStatusDistribution:
          Json.list(json['orderStatusDistribution'], StatusCount.fromJson),
      totalRevenue: Json.dbl(json['totalRevenue']),
      totalOrders: Json.integer(json['totalOrders']),
      averageOrderValue: Json.dbl(json['averageOrderValue']),
    );
  }
}
