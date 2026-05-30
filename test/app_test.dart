import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novaishop_mobile/app/novaishop_app.dart';
import 'package:novaishop_mobile/core/session/session_scope.dart';
import 'package:novaishop_mobile/data/repositories/address_repository.dart';
import 'package:novaishop_mobile/data/repositories/catalog_repository.dart';
import 'package:novaishop_mobile/data/repositories/order_repository.dart';
import 'package:novaishop_mobile/features/auth/auth_controller.dart';
import 'package:novaishop_mobile/features/cart/cart_controller.dart';
import 'package:novaishop_mobile/features/settings/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows home when no session is stored', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthController()..restore()),
          ChangeNotifierProvider(create: (_) => CartController()),
          ChangeNotifierProvider(create: (_) => ThemeController()..restore()),
          ChangeNotifierProxyProvider<AuthController, SessionScope>(
            create: (_) => SessionScope(),
            update: (_, auth, scope) {
              (scope ?? SessionScope()).update(
                accessToken: auth.accessToken,
                role: auth.user?.role,
              );
              return scope ?? SessionScope();
            },
          ),
          Provider(create: (_) => AddressRepository()),
          ProxyProvider<AuthController, CatalogRepository>(
            update: (_, auth, __) =>
                CatalogRepository(accessToken: auth.accessToken),
          ),
          ProxyProvider<AuthController, OrderRepository>(
            update: (_, auth, __) =>
                OrderRepository(accessToken: auth.accessToken),
          ),
        ],
        child: const NovaShopApp(authStateChanges: Stream.empty()),
      ),
    );

    // First frame shows the splash, then restore() resolves to the guest home.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Suivant'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
