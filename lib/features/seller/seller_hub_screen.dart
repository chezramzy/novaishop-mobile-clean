import 'package:flutter/material.dart';

import '../../data/models/auth_user.dart';
import 'seller_home_tab.dart';

/// The seller hub. Kept as a thin wrapper for callers (e.g. the profile
/// screen) that push the seller workspace imperatively. The full dashboard
/// lives in [SellerHomeTab], which reads the authenticated session itself.
class SellerHubScreen extends StatelessWidget {
  const SellerHubScreen({this.user, super.key});

  /// Retained for backward compatibility with existing callers.
  final AuthUser? user;

  @override
  Widget build(BuildContext context) => const SellerHomeTab();
}
