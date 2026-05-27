import 'package:flutter/material.dart';

import 'shop_tab.dart';

/// Backwards-compatible catalogue screen for older route callers.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) => const ShopTab();
}
