import 'package:flutter/material.dart';

import '../../design/components/soft_gradient_scaffold.dart';
import '../../design/feedback/nova_empty_state.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/cart/checkout_routes.dart';
import '../../features/catalog/discovery_routes.dart';
import '../../features/delivery/delivery_routes.dart';
import '../../features/orders/orders_routes.dart';
import '../../features/product/product_routes.dart';
import '../../features/profile/account_routes.dart';
import '../../features/seller/seller_routes.dart';
import 'route_transitions.dart';

/// A feature's contribution to the route table.
///
/// Each feature declares one of these in its own `<feature>_routes.dart`
/// and adds it to [AppRouter.featureRoutes]. A [FeatureRoutes] maps route
/// names to builders that receive the optional route `arguments`.
typedef RouteArgsBuilder = Widget Function(Object? arguments);

class FeatureRoutes {
  const FeatureRoutes(this.routes);

  /// Route name -> builder.
  final Map<String, RouteArgsBuilder> routes;
}

/// The central router. Merges a fixed list of per-feature route maps and
/// resolves them through [onGenerateRoute] with animated transitions.
///
/// Imperative navigation is kept — features push routes by name with
/// `Navigator.pushNamed(context, RouteNames.x, arguments: ...)`.
class AppRouter {
  const AppRouter._();

  /// The ordered list of feature route contributions.
  ///
  /// Each `<feature>_routes.dart` exposes one `FeatureRoutes` value; this
  /// list references them all. A feature agent only edits ITS OWN
  /// `<feature>_routes.dart` map — never this file — so there is no
  /// shared edit point between the parallel workstreams.
  static final List<FeatureRoutes> featureRoutes = <FeatureRoutes>[
    discoveryRoutes, // WS1 — découverte & catalogue
    productRoutes, // WS2 — produit, avis, boutique
    checkoutRoutes, // WS3 — panier, checkout, paiement
    ordersRoutes, // WS4 — commandes, favoris, adresses
    authRoutes, // WS5 — auth & onboarding
    accountRoutes, // WS6 — profil, réglages, support, notifications
    sellerRoutes, // WS7 — espace vendeur
    deliveryRoutes, // WS8 — livraison & assistant IA
  ];

  /// The flattened route table, built once from [featureRoutes].
  static Map<String, RouteArgsBuilder> get _table {
    final merged = <String, RouteArgsBuilder>{};
    for (final feature in featureRoutes) {
      merged.addAll(feature.routes);
    }
    return merged;
  }

  /// `MaterialApp.onGenerateRoute` callback.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = _table[settings.name];
    if (builder != null) {
      return buildRoute(
        builder(settings.arguments),
        settings: settings,
      );
    }
    return buildRoute(
      _UnknownRouteScreen(routeName: settings.name),
      settings: settings,
      style: RouteTransitionStyle.fade,
    );
  }
}

/// Shown when a route name is not registered by any feature.
class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: NovaEmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Page introuvable',
        message: routeName == null
            ? "Cette page n'existe pas encore."
            : "La page « $routeName » n'est pas disponible.",
        actionLabel: 'Retour',
        onAction: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
