import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/auth_user.dart';
import '../../design/design_system.dart';
import 'auth_controller.dart';
import 'auth_redirect.dart';
import 'widgets/auth_scaffold.dart';

/// Final registration step: confirm the email address with a 4-digit code.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({required this.email, this.redirect, super.key});

  final String email;
  final AuthRedirect? redirect;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const _digits = 4;
  static const _resendDelay = 45;

  final List<TextEditingController> _controllers =
      List.generate(_digits, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_digits, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = _resendDelay;
  bool _verifying = false;

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendDelay);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _digits - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_code.length == _digits) _verify();
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    try {
      await context
          .read<AuthController>()
          .resendEmailVerification(widget.email);
      if (!mounted) return;
      _startCountdown();
      showAuthMessage(
        context,
        'Un nouveau code est en route.',
        isError: false,
      );
    } on AuthException catch (error) {
      if (mounted) showAuthMessage(context, error.message);
    }
  }

  Future<void> _verify() async {
    if (_verifying) return;
    if (_code.length < _digits) {
      showAuthMessage(context, 'Saisissez le code à 4 chiffres complet.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      await context.read<AuthController>().verifyEmailOtp(
            email: widget.email,
            token: _code,
          );
      if (!mounted) return;
      setState(() => _verifying = false);
      _showWelcome();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _verifying = false);
      showAuthMessage(context, error.message);
    }
  }

  void _skip() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showWelcome() {
    final user = context.read<AuthController>().user;
    final isSeller = user?.role.isSeller ?? false;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: const BoxDecoration(
                color: AppColors.lime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppColors.ink,
              ),
            ).popIn(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tout est prêt !',
              style: AppTypography.headline,
            ).fadeSlideIn(delay: const Duration(milliseconds: 80)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Votre compte NovaShop est vérifié. Bienvenue sur '
              'la marketplace.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted,
            ).fadeSlideIn(delay: const Duration(milliseconds: 140)),
            if (isSeller) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Prochaine etape : ouvrez votre espace partenaire et publiez votre premier produit.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted,
              ).fadeSlideIn(delay: const Duration(milliseconds: 160)),
            ],
            const SizedBox(height: AppSpacing.xl),
            NovaButton.primary(
              label:
                  isSeller ? 'Configurer mon espace' : 'Commencer mes achats',
              icon: isSeller
                  ? Icons.storefront_outlined
                  : Icons.shopping_bag_outlined,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                final redirect = widget.redirect;
                if (redirect != null) {
                  Navigator.of(context)
                      .pushReplacementNamed(redirect.routeName);
                } else {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ).fadeSlideIn(delay: const Duration(milliseconds: 200)),
          ],
        ),
      ),
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
          AuthIntro(
            icon: Icons.mark_email_unread_outlined,
            showBack: false,
            title: 'Vérifiez votre e-mail',
            subtitle:
                'Saisissez le code à 4 chiffres envoyé à ${widget.email}.',
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var index = 0; index < _digits; index++)
                _OtpBox(
                  controller: _controllers[index],
                  node: _nodes[index],
                  onChanged: (value) => _onDigitChanged(index, value),
                ).popIn(delay: AppMotion.stagger * index),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: _secondsLeft > 0
                ? Text(
                    'Renvoyer le code dans '
                    '0:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : TextButton(
                    onPressed: _resend,
                    child: Text(
                      'Renvoyer le code',
                      style: AppTypography.body.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          NovaButton.primary(
            label: 'Vérifier et continuer',
            busy: _verifying,
            onPressed: _verify,
          ).fadeSlideIn(delay: const Duration(milliseconds: 260)),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: _verifying ? null : _skip,
              child: Text(
                'Je vérifierai plus tard',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.node,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode node;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.isNotEmpty;
    return SizedBox(
      width: 64,
      height: 68,
      child: TextField(
        controller: controller,
        focusNode: node,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: context.colors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: filled ? AppColors.lime : context.colors.border,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: context.colors.textPrimary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
