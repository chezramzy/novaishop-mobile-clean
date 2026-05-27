import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/nova_colors.dart';

/// Form validation helpers shared across every form in the app.
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

  /// Validates a positive numeric amount.
  static String? amount(String? value, {String field = 'Le montant'}) {
    final base = required(value, field: field);
    if (base != null) return base;
    final parsed = double.tryParse(value!.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return '$field doit être un nombre positif.';
    }
    return null;
  }
}

/// The generalised, labelled text field of the design system.
///
/// Supports a label, hint, leading icon, validator, helper text,
/// multiline input and an optional built-in password visibility toggle.
class NovaTextField extends StatefulWidget {
  const NovaTextField({
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
    this.readOnly = false,
    this.onFieldSubmitted,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.helperText,
    this.password = false,
    this.suffix,
    this.autofocus = false,
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
  final bool readOnly;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final String? helperText;

  /// When true, obscures input and shows a visibility toggle.
  final bool password;

  /// A custom trailing widget (ignored when [password] is true).
  final Widget? suffix;
  final bool autofocus;

  @override
  State<NovaTextField> createState() => _NovaTextFieldState();
}

class _NovaTextFieldState extends State<NovaTextField> {
  late bool _obscured = widget.password;

  @override
  Widget build(BuildContext context) {
    Widget? suffixIcon;
    if (widget.password) {
      suffixIcon = IconButton(
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      );
    } else {
      suffixIcon = widget.suffix;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          obscureText: _obscured,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          maxLines: widget.password ? 1 : widget.maxLines,
          minLines: widget.password ? 1 : widget.minLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            prefixIcon: widget.icon == null ? null : Icon(widget.icon),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
