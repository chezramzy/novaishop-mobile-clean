import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/auth_user.dart';
import '../design/components/app_bottom_nav.dart';
import '../features/assistant/assistant_tab.dart';
import '../features/auth/auth_controller.dart';
import '../features/delivery/driver_deliveries_tab.dart';
import '../features/delivery/driver_home_tab.dart';
import '../features/home/home_tab.dart';
import '../features/profile/profile_tab.dart';
import '../features/seller/seller_home_tab.dart';
import '../features/shop/shop_tab.dart';

/// The authenticated app shell. The bottom-navigation set adapts to the
/// signed-in user's [AccountRole]:
///
/// * buyer  → Accueil / Catalogue / Assistant / Profil
/// * partner → Accueil / Produits / Assistant / Profil
/// * driver → Tournée / Livraisons / Assistant / Profil
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int? _index;

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthController, AccountRole?>(
      (auth) => auth.user?.role,
    );
    final tabs = _tabsFor(role);
    final defaultIndex = role != null && role.isSeller ? 1 : 0;

    // Keep the index valid if the role (and tab count) changes.
    final safeIndex = (_index ?? defaultIndex).clamp(0, tabs.length - 1);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: [for (final tab in tabs) tab.screen],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: safeIndex,
        destinations: [
          for (final tab in tabs) NavDestination(tab.icon, tab.label),
        ],
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }

  List<_ShellTab> _tabsFor(AccountRole? role) {
    if (role != null && role.isSeller) {
      return const [
        _ShellTab(Icons.home_outlined, 'Accueil', HomeTab()),
        _ShellTab(Icons.inventory_2_outlined, 'Produits', SellerHomeTab()),
        _ShellTab(
          Icons.auto_awesome_outlined,
          'Assistant',
          AssistantTab(),
        ),
        _ShellTab(Icons.person_outline_rounded, 'Profil', ProfileTab()),
      ];
    }
    if (role != null && role.isDriver) {
      return const [
        _ShellTab(Icons.route_outlined, 'Tournée', DriverHomeTab()),
        _ShellTab(
          Icons.local_shipping_outlined,
          'Livraisons',
          DriverDeliveriesTab(),
        ),
        _ShellTab(
          Icons.auto_awesome_outlined,
          'Assistant',
          AssistantTab(),
        ),
        _ShellTab(Icons.person_outline_rounded, 'Profil', ProfileTab()),
      ];
    }
    // Buyer (default).
    return const [
      _ShellTab(Icons.home_outlined, 'Accueil', HomeTab()),
      _ShellTab(Icons.grid_view_rounded, 'Catalogue', ShopTab()),
      _ShellTab(Icons.auto_awesome_outlined, 'Assistant', AssistantTab()),
      _ShellTab(Icons.person_outline_rounded, 'Profil', ProfileTab()),
    ];
  }
}

class _ShellTab {
  const _ShellTab(this.icon, this.label, this.screen);

  final IconData icon;
  final String label;
  final Widget screen;
}
