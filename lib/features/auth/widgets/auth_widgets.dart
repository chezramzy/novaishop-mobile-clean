import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/tokens/app_colors.dart';

/// Form validation helpers shared across the authentication screens.
class Validators {
  const Validators._();

  static String? required(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field est obligatoire.';
    }
    return null;
  }

  static String? name(String? value, {String field = 'Ce champ'}) {
    final base = required(value, field: field);
    if (base != null) return base;
    if (value!.trim().length < 2) {
      return '$field est trop court.';
    }
    return null;
  }

  static String? email(String? value) {
    final base = required(value, field: "L'e-mail");
    if (base != null) return base;
    final pattern = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!pattern.hasMatch(value!.trim())) {
      return 'Saisissez une adresse e-mail valide.';
    }
    return null;
  }

  static String? phone(String? value, {bool optional = false}) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : 'Le numéro de téléphone est obligatoire.';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) {
      return 'Saisissez un numéro de téléphone valide.';
    }
    return null;
  }

  static String? password(String? value) {
    final base = required(value, field: 'Le mot de passe');
    if (base != null) return base;
    if (value!.length < 8) {
      return 'Utilisez au moins 8 caractères.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Mélangez lettres et chiffres.';
    }
    return null;
  }
}

/// Compact header used at the top of an auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.title,
    required this.subtitle,
    this.showBack = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox.square(
              dimension: 44,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.ink,
                ),
              ),
            ),
          ),
        SizedBox(height: showBack ? 22 : 0),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

/// Labeled text field used in every auth form.
class AuthField extends StatelessWidget {
  const AuthField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.helperText,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final ValueChanged<String>? onFieldSubmitted;
  final int maxLines;
  final int? minLines;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.deepInk,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: icon == null ? null : Icon(icon),
          ),
        ),
      ],
    );
  }
}

/// Password field with a visibility toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    this.label = 'Mot de passe',
    this.hint = '••••••••',
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.deepInk,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscured = !_obscured),
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary call-to-action button that shows an inline spinner while busy.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.ink,
              ),
            )
          : Text(label),
    );
  }
}

/// "Or continue with" divider plus the social provider buttons.
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow(
      {required this.onProvider, this.enabled = true, super.key});

  final ValueChanged<String> onProvider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFD7E2CC))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Ou continuez avec',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFD7E2CC))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SocialButton(
              label: 'Google',
              icon: Icons.g_mobiledata_rounded,
              onTap: enabled ? () => onProvider('Google') : null,
            ),
            const SizedBox(width: 12),
            _SocialButton(
              label: 'Apple',
              icon: Icons.apple_rounded,
              onTap: enabled ? () => onProvider('Apple') : null,
            ),
            const SizedBox(width: 12),
            _SocialButton(
              label: 'Facebook',
              icon: Icons.facebook_rounded,
              onTap: enabled ? () => onProvider('Facebook') : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 26, color: AppColors.deepInk),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress dots shared by the multi-step registration flow.
class StepDots extends StatelessWidget {
  const StepDots({required this.current, this.count = 3, super.key});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < count; index++)
          Container(
            margin: const EdgeInsets.only(right: 6),
            height: 8,
            width: index == current ? 26 : 8,
            decoration: BoxDecoration(
              color: index <= current
                  ? AppColors.deepInk
                  : AppColors.deepInk.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Shows a themed error snackbar.
void showAuthError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepInk,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
}
