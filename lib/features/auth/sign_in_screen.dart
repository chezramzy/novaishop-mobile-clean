import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../design/design_system.dart';
import 'auth_controller.dart';
import 'auth_redirect.dart';
import 'widgets/auth_scaffold.dart';

/// Email + password sign-in screen.
class SignInScreen extends StatefulWidget {
  const SignInScreen({this.redirect, super.key});

  final AuthRedirect? redirect;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _closeToShell() {
    final redirect = widget.redirect;
    if (redirect != null) {
      Navigator.of(context).pushReplacementNamed(redirect.routeName);
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (auth.isBusy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    auth.setBusy(true);
    try {
      await auth.signIn(email: _identifier.text, password: _password.text);
      if (mounted) _closeToShell();
    } on AuthException catch (error) {
      if (mounted) showAuthMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        showAuthMessage(context, 'Connexion impossible. Veuillez réessayer.');
      }
    } finally {
      if (mounted) auth.setBusy(false);
    }
  }

  Future<void> _signInWithProvider(String provider) async {
    final auth = context.read<AuthController>();
    if (auth.isBusy) return;

    auth.setBusy(true);
    try {
      await auth.signInWithProvider(provider);
      if (mounted) _closeToShell();
    } on AuthException catch (error) {
      if (mounted) showAuthMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        showAuthMessage(context, 'Impossible de continuer avec $provider.');
      }
    } finally {
      if (mounted) auth.setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().isBusy;

    return SoftGradientScaffold(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            const AuthIntro(
              icon: Icons.lock_open_rounded,
              title: 'Content de vous revoir',
              subtitle: 'Connectez-vous pour continuer vos achats et gérer '
                  'votre compte.',
            ),
            const SizedBox(height: AppSpacing.xl),
            NovaTextField(
              controller: _identifier,
              label: 'E-mail ou téléphone',
              hint: 'vous@email.com ou +229...',
              icon: Icons.account_circle_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Identifiant requis.';
                if (text.contains('@')) return Validators.email(text);
                return Validators.phone(text, optional: false);
              },
            ).fadeSlideIn(delay: const Duration(milliseconds: 160)),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _password,
              label: 'Mot de passe',
              hint: 'Votre mot de passe',
              icon: Icons.lock_outline_rounded,
              password: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  Validators.required(value, field: 'Le mot de passe'),
            ).fadeSlideIn(delay: const Duration(milliseconds: 220)),
            const SizedBox(height: AppSpacing.xxs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.of(context)
                        .pushNamed(RouteNames.forgotPassword),
                child: Text(
                  'Mot de passe oublié ?',
                  style: AppTypography.body.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            NovaButton.primary(
              label: 'Se connecter',
              busy: busy,
              onPressed: _submit,
            ).fadeSlideIn(delay: const Duration(milliseconds: 280)),
            const SizedBox(height: AppSpacing.xl),
            SocialAuthBlock(
              enabled: !busy,
              onProvider: _signInWithProvider,
            ).fadeSlideIn(delay: const Duration(milliseconds: 340)),
            const SizedBox(height: AppSpacing.xl),
            AuthFooterLink(
              leading: 'Pas encore de compte ?',
              action: 'Créer un compte',
              onTap: busy
                  ? null
                  : () => Navigator.of(context).pushReplacementNamed(
                        RouteNames.signUp,
                        arguments:
                            widget.redirect ?? widget.redirect?.signUpRole,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
