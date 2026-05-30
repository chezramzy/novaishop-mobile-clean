import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/novaishop_app.dart';
import 'core/session/session_scope.dart';
import 'core/supabase/supabase_config.dart';
import 'data/repositories/address_repository.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/ai_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/coupon_repository.dart';
import 'data/repositories/driver_repository.dart';
import 'data/repositories/media_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/partner_application_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/seller_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/wishlist_repository.dart';
import 'features/auth/auth_controller.dart';
import 'features/cart/cart_controller.dart';
import 'features/settings/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
  );
  runApp(const _Bootstrap());
}

/// The composition root. Wires controllers and repositories.
///
/// Conventions:
/// * Public repositories (no auth needed) → plain [Provider].
/// * Token-dependent repositories → [ProxyProvider] on [AuthController] so
///   they are rebuilt whenever the access token changes.
/// * [SessionScope] mirrors [AuthController]'s token + role for shared
///   infrastructure that should not depend on the full controller.
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // -------- Controllers --------
        ChangeNotifierProvider(create: (_) => AuthController()..restore()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => ThemeController()..restore()),

        // -------- Session mirror --------
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

        // -------- Public repositories (no token) --------
        Provider(create: (_) => AddressRepository()),
        Provider(create: (_) => const AdminRepository()),

        // -------- Token-dependent repositories --------
        // Catalog & shop forward the token (admins see unpublished data)
        // but tolerate its absence, so they rebuild on token change too.
        ProxyProvider<AuthController, CatalogRepository>(
          update: (_, auth, __) =>
              CatalogRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, ShopRepository>(
          update: (_, auth, __) =>
              ShopRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, OrderRepository>(
          update: (_, auth, __) =>
              OrderRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, SellerRepository>(
          update: (_, auth, __) =>
              SellerRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, ReviewRepository>(
          update: (_, auth, __) =>
              ReviewRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, WishlistRepository>(
          update: (_, auth, __) =>
              WishlistRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, CouponRepository>(
          update: (_, auth, __) =>
              CouponRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, PaymentRepository>(
          update: (_, auth, __) =>
              PaymentRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, PartnerApplicationRepository>(
          update: (_, auth, __) =>
              PartnerApplicationRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, NotificationRepository>(
          update: (_, auth, __) =>
              NotificationRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, MessageRepository>(
          update: (_, auth, __) =>
              MessageRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, DriverRepository>(
          update: (_, auth, __) =>
              DriverRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, AiRepository>(
          update: (_, auth, __) => AiRepository(accessToken: auth.accessToken),
        ),
        ProxyProvider<AuthController, MediaRepository>(
          update: (_, auth, __) =>
              MediaRepository(accessToken: auth.accessToken),
        ),
      ],
      child: const NovaShopApp(),
    );
  }
}
