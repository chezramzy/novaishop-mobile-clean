import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design_system.dart';
import '../auth/auth_controller.dart';

/// Formulaire de changement de mot de passe.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_next.text != _confirm.text) {
      _showError('Les nouveaux mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _busy = true);
    try {
      await context.read<AuthController>().changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.deepInk,
            content: Text(
              'Mot de passe mis à jour avec succès.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) {
        _showError('Impossible de mettre à jour le mot de passe.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            const ScreenHeader(title: 'Mot de passe'),
            const SizedBox(height: AppSpacing.lg),
            NovaCard(
              color: context.colors.lavender,
              elevated: false,
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: context.colors.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Choisissez un mot de passe d’au moins 8 caractères '
                      'mélangeant lettres et chiffres.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ).fadeSlideIn(),
            const SizedBox(height: AppSpacing.md),
            NovaCard(
              child: Column(
                children: [
                  NovaTextField(
                    controller: _current,
                    label: 'Mot de passe actuel',
                    icon: Icons.lock_outline_rounded,
                    password: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) => Validators.required(
                      value,
                      field: 'Le mot de passe actuel',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NovaTextField(
                    controller: _next,
                    label: 'Nouveau mot de passe',
                    icon: Icons.lock_reset_rounded,
                    password: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NovaTextField(
                    controller: _confirm,
                    label: 'Confirmer le nouveau mot de passe',
                    icon: Icons.lock_reset_rounded,
                    password: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    validator: (value) => Validators.required(
                      value,
                      field: 'La confirmation',
                    ),
                  ),
                ],
              ),
            ).fadeSlideIn(delay: AppMotion.fast),
            const SizedBox(height: AppSpacing.xl),
            NovaButton.primary(
              label: 'Mettre à jour le mot de passe',
              busy: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
