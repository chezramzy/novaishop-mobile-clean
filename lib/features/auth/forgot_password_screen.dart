import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../design/design_system.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Lets the user request a password-reset email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await context.read<AuthController>().sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        showAuthMessage(
          context,
          "Impossible d'envoyer l'e-mail. Veuillez réessayer.",
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          if (_sent) _buildSuccess(context) else _buildForm(),
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
          const AuthIntro(
            icon: Icons.lock_reset_rounded,
            title: 'Mot de passe oublié ?',
            subtitle: "Saisissez l'e-mail lié à votre compte et nous vous "
                'enverrons un lien de réinitialisation.',
          ),
          const SizedBox(height: AppSpacing.xl),
          NovaTextField(
            controller: _email,
            label: 'E-mail',
            hint: 'vous@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _submit(),
          ).fadeSlideIn(delay: const Duration(milliseconds: 160)),
          const SizedBox(height: AppSpacing.lg),
          NovaButton.primary(
            label: 'Envoyer le lien',
            busy: _busy,
            onPressed: _submit,
          ).fadeSlideIn(delay: const Duration(milliseconds: 220)),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
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
              Icons.mark_email_read_outlined,
              size: 44,
              color: AppColors.ink,
            ),
          ).popIn(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Consultez votre boîte mail',
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ).fadeSlideIn(delay: const Duration(milliseconds: 80)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Si un compte existe pour ${_email.text.trim()}, un lien de '
          'réinitialisation est en route. Le lien expire dans 1 heure.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ).fadeSlideIn(delay: const Duration(milliseconds: 140)),
        const SizedBox(height: AppSpacing.xl),
        NovaButton.primary(
          label: "J'ai reçu le lien",
          icon: Icons.lock_reset_rounded,
          onPressed: () =>
              Navigator.of(context).pushNamed(RouteNames.resetPassword),
        ).fadeSlideIn(delay: const Duration(milliseconds: 200)),
        const SizedBox(height: AppSpacing.xs),
        NovaButton.ghost(
          label: 'Retour à la connexion',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: AppSpacing.xxs),
        TextButton(
          onPressed: () => setState(() => _sent = false),
          child: Text(
            'Utiliser un autre e-mail',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}
