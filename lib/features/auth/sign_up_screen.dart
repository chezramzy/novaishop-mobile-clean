import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/auth_user.dart';
import '../../design/design_system.dart';
import 'auth_controller.dart';
import 'auth_redirect.dart';
import 'widgets/auth_scaffold.dart';

/// Step 2 of registration: collect the account details for the chosen role.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({required this.role, this.redirect, super.key});

  final AccountRole role;
  final AuthRedirect? redirect;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _businessName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _acceptedTerms = false;

  bool get _phoneRequired => widget.role.isSeller || widget.role.isDriver;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _businessName.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (auth.isBusy) return;
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_password.text != _confirmPassword.text) {
      showAuthMessage(context, 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    if (!_acceptedTerms) {
      showAuthMessage(
        context,
        'Veuillez accepter les conditions pour continuer.',
      );
      return;
    }

    auth.setBusy(true);
    try {
      await auth.signUp(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        password: _password.text,
        role: widget.role,
        phone: _phone.text,
        businessName: _businessName.text,
      );
      if (!mounted) return;
      final redirect = widget.redirect;
      if (auth.needsEmailVerification) {
        Navigator.of(context).pushReplacementNamed(
          RouteNames.verification,
          arguments: AuthVerificationArgs(
            email: _email.text.trim(),
            redirect: redirect,
          ),
        );
        return;
      }
      if (redirect != null) {
        Navigator.of(context).pushReplacementNamed(redirect.routeName);
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      if (mounted) showAuthMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        showAuthMessage(
          context,
          'Une erreur est survenue. Veuillez réessayer.',
        );
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
              title: 'Créer votre compte',
              subtitle: 'Quelques informations et votre compte marketplace '
                  'est prêt.',
            ),
            const SizedBox(height: AppSpacing.md),
            const AuthStepIndicator(current: 1)
                .fadeSlideIn(delay: const Duration(milliseconds: 140)),
            const SizedBox(height: AppSpacing.md),
            _RoleBadge(role: widget.role)
                .fadeSlideIn(delay: const Duration(milliseconds: 180)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: NovaTextField(
                    controller: _firstName,
                    label: 'Prénom',
                    hint: 'Jeanne',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validators.name(value, field: 'Le prénom'),
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: NovaTextField(
                    controller: _lastName,
                    label: 'Nom',
                    hint: 'Cooper',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validators.name(value, field: 'Le nom'),
                  ),
                ),
              ],
            ).fadeSlideIn(delay: const Duration(milliseconds: 220)),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _email,
              label: 'E-mail',
              hint: 'vous@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ).fadeSlideIn(delay: const Duration(milliseconds: 280)),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _phone,
              label: _phoneRequired
                  ? 'Numéro de téléphone'
                  : 'Numéro de téléphone (facultatif)',
              hint: '+33 6 12 34 56 78',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
              ],
              validator: (value) =>
                  Validators.phone(value, optional: !_phoneRequired),
            ).fadeSlideIn(delay: const Duration(milliseconds: 340)),
            if (widget.role.requiresBusinessName) ...[
              const SizedBox(height: AppSpacing.md),
              NovaTextField(
                controller: _businessName,
                label: "Nom de l'entreprise",
                hint: 'Raison sociale enregistrée',
                icon: Icons.business_outlined,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.name(value, field: "Le nom de l'entreprise"),
              ).fadeSlideIn(delay: const Duration(milliseconds: 380)),
            ],
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _password,
              label: 'Mot de passe',
              hint: 'Au moins 8 caractères',
              icon: Icons.lock_outline_rounded,
              password: true,
              textInputAction: TextInputAction.next,
              helperText: 'Mélangez lettres et chiffres.',
              validator: Validators.password,
            ).fadeSlideIn(delay: const Duration(milliseconds: 420)),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _confirmPassword,
              label: 'Confirmer le mot de passe',
              hint: 'Ressaisissez le mot de passe',
              icon: Icons.lock_outline_rounded,
              password: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  Validators.required(value, field: 'La confirmation'),
            ).fadeSlideIn(delay: const Duration(milliseconds: 460)),
            const SizedBox(height: AppSpacing.md),
            _TermsRow(
              value: _acceptedTerms,
              onChanged: (value) => setState(() => _acceptedTerms = value),
            ).fadeSlideIn(delay: const Duration(milliseconds: 500)),
            const SizedBox(height: AppSpacing.lg),
            NovaButton.primary(
              label: 'Créer le compte',
              busy: busy,
              onPressed: _submit,
            ).fadeSlideIn(delay: const Duration(milliseconds: 540)),
            const SizedBox(height: AppSpacing.sm),
            AuthFooterLink(
              leading: 'Vous avez déjà un compte ?',
              action: 'Se connecter',
              onTap: busy
                  ? null
                  : () => Navigator.of(context).pushReplacementNamed(
                        RouteNames.signIn,
                        arguments: widget.redirect,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final AccountRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(role.icon, color: AppColors.ink),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.label,
                  style: AppTypography.subtitle.copyWith(color: Colors.white),
                ),
                Text(
                  role.tagline,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: .65),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text(
              'Modifier',
              style: TextStyle(
                color: AppColors.lime,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.lime : context.colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: value ? AppColors.lime : AppColors.muted,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.ink,
                    )
                  : null,
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.caption.copyWith(height: 1.4),
                    children: [
                      const TextSpan(text: "J'accepte les "),
                      TextSpan(
                        text: "Conditions d'utilisation",
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' et la '),
                      TextSpan(
                        text: 'Politique de confidentialité',
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
