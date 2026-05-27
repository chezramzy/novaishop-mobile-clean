import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../design/design_system.dart';
import 'widgets/auth_scaffold.dart';

/// Lets the user define a new password after following a reset link.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({this.email = '', super.key});

  /// The email address tied to the reset request, shown for context.
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_password.text != _confirmPassword.text) {
      showAuthMessage(context, 'Les deux mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _busy = true);
    // The reset confirmation endpoint will be branched via Supabase Auth.
    await Future<void>.delayed(AppMotion.slow);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = true;
    });
  }

  void _backToSignIn() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.signIn,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          if (_done) _buildSuccess() else _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthIntro(
            icon: Icons.password_rounded,
            title: 'Nouveau mot de passe',
            subtitle: widget.email.isEmpty
                ? 'Choisissez un nouveau mot de passe sûr pour votre compte.'
                : 'Choisissez un nouveau mot de passe pour ${widget.email}.',
          ),
          const SizedBox(height: AppSpacing.xl),
          NovaTextField(
            controller: _password,
            label: 'Nouveau mot de passe',
            hint: 'Au moins 8 caractères',
            icon: Icons.lock_outline_rounded,
            password: true,
            textInputAction: TextInputAction.next,
            helperText: 'Mélangez lettres et chiffres.',
            validator: Validators.password,
          ).fadeSlideIn(delay: const Duration(milliseconds: 160)),
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
          ).fadeSlideIn(delay: const Duration(milliseconds: 220)),
          const SizedBox(height: AppSpacing.lg),
          NovaButton.primary(
            label: 'Réinitialiser le mot de passe',
            busy: _busy,
            onPressed: _submit,
          ).fadeSlideIn(delay: const Duration(milliseconds: 280)),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Container(
            height: 88,
            width: 88,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              size: 44,
              color: AppColors.ink,
            ),
          ).popIn(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Mot de passe mis à jour',
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ).fadeSlideIn(delay: const Duration(milliseconds: 80)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Votre mot de passe a été réinitialisé. Connectez-vous avec '
          'vos nouveaux identifiants.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ).fadeSlideIn(delay: const Duration(milliseconds: 140)),
        const SizedBox(height: AppSpacing.xl),
        NovaButton.primary(
          label: 'Se connecter',
          icon: Icons.login_rounded,
          onPressed: _backToSignIn,
        ).fadeSlideIn(delay: const Duration(milliseconds: 200)),
      ],
    );
  }
}
