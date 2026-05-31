import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../../data/models/auth_user.dart';
import 'auth_redirect.dart';
import 'forgot_password_screen.dart';
import 'onboarding_screen.dart';
import 'reset_password_screen.dart';
import 'role_selection_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'verification_screen.dart';

/// Routes contributed by WS5 (authentification & onboarding).
final FeatureRoutes authRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.onboarding: (_) => const OnboardingScreen(),
  RouteNames.signIn: (args) => SignInScreen(
        redirect: args is AuthRedirect ? args : null,
      ),
  RouteNames.roleSelection: (_) => const RoleSelectionScreen(),
  RouteNames.signUp: (args) {
    if (args is AuthRedirect) {
      return SignUpScreen(role: args.signUpRole, redirect: args);
    }
    return SignUpScreen(
      role: args is AccountRole ? args : AccountRole.individualBuyer,
    );
  },
  RouteNames.verification: (args) {
    if (args is AuthVerificationArgs) {
      return VerificationScreen(
        email: args.email,
        redirect: args.redirect,
      );
    }
    return VerificationScreen(email: args is String ? args : '');
  },
  RouteNames.forgotPassword: (_) => const ForgotPasswordScreen(),
  RouteNames.resetPassword: (args) => ResetPasswordScreen(
        email: args is String ? args : '',
      ),
});
