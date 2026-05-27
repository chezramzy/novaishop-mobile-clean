import 'package:flutter/material.dart';

import 'shop_tab.dart';

/// Deprecated compatibility args. Public shop pages now resolve to the unified
/// NovaShop catalogue so partner identities stay private.
class ShopPageArgs {
  const ShopPageArgs({required this.slug, this.shopName});

  final String slug;
  final String? shopName;
}

class ShopPageScreen extends StatelessWidget {
  const ShopPageScreen({required this.slug, this.shopName, super.key});

  final String slug;
  final String? shopName;

  @override
  Widget build(BuildContext context) => const ShopTab();
}
