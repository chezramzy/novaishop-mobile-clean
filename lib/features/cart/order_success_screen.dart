import 'package:flutter/material.dart';

import '../checkout/order_confirmation_screen.dart';

/// Backwards-compatible alias for the post-checkout confirmation screen.
///
/// The canonical implementation now lives in
/// [OrderConfirmationScreen] (`features/checkout/`); this thin wrapper is
/// kept so older imports keep compiling.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    required this.orderNumber,
    required this.total,
    required this.itemCount,
    super.key,
  });

  final String orderNumber;
  final double total;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return OrderConfirmationScreen(
      orderNumber: orderNumber,
      total: total,
      itemCount: itemCount,
    );
  }
}
