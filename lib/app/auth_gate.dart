import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/auth_controller.dart';
import '../design/components/soft_gradient_scaffold.dart';
import '../design/tokens/app_colors.dart';
import 'app_shell.dart';

/// Shows the app immediately after session restore.
///
/// Visitors can browse the catalogue without an account; authentication is
/// requested only for actions that need an identity.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.initialized) {
      return const _SplashView();
    }
    return const AppShell();
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: AppColors.deepInk,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: AppColors.lime,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'NovaShop',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Le catalogue NovaShop unifie',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 26),
            const SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: AppColors.deepInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
