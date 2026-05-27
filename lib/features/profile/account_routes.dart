import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../../data/models/auth_user.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../support/contact_screen.dart';
import '../support/faq_screen.dart';
import '../support/legal_screen.dart';
import '../support/partner_application_screen.dart';
import '../support/support_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_tab.dart';

/// Routes contributed by WS6 (profil, réglages, support, notifications).
final FeatureRoutes accountRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.profile: (_) => const ProfileTab(),
  RouteNames.editProfile: (args) =>
      EditProfileScreen(user: args is AuthUser ? args : null),
  RouteNames.changePassword: (_) => const ChangePasswordScreen(),
  RouteNames.settings: (_) => const SettingsScreen(),
  RouteNames.notifications: (_) => const NotificationsScreen(),
  RouteNames.support: (_) => const SupportScreen(),
  RouteNames.faq: (_) => const FaqScreen(),
  RouteNames.legal: (args) => LegalScreen(
        topic: args is LegalTopic ? args : LegalTopic.notice,
      ),
  RouteNames.contact: (_) => const ContactScreen(),
  RouteNames.partnerApplication: (_) => const PartnerApplicationScreen(),
});
