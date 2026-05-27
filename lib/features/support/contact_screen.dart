import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/design_system.dart';
import 'support_content.dart';

/// Écran de contact : canaux directs (e-mail, téléphone) et formulaire de
/// message vers le support.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AppColors.danger : AppColors.deepInk,
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
  }

  Future<void> _launch(Uri uri, String fallbackLabel) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _toast('Impossible d’ouvrir $fallbackLabel.', error: true);
      }
    } catch (_) {
      if (mounted) _toast('Impossible d’ouvrir $fallbackLabel.', error: true);
    }
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sending = true);
    final uri = Uri(
      scheme: 'mailto',
      path: SupportContent.supportEmail,
      query: _encodeQuery({
        'subject': _subject.text.trim(),
        'body': _message.text.trim(),
      }),
    );
    await _launch(uri, 'votre messagerie');
    if (mounted) {
      setState(() => _sending = false);
      _toast('Votre message a été préparé dans votre messagerie.');
    }
  }

  static String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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
            40 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            const ScreenHeader(title: 'Nous contacter'),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Canaux directs'),
            const SizedBox(height: AppSpacing.sm),
            _ChannelTile(
              icon: Icons.mail_outline_rounded,
              title: 'Envoyer un e-mail',
              value: SupportContent.supportEmail,
              onTap: () => _launch(
                Uri(scheme: 'mailto', path: SupportContent.supportEmail),
                'votre messagerie',
              ),
            ).fadeSlideIn(),
            const SizedBox(height: AppSpacing.xs),
            _ChannelTile(
              icon: Icons.phone_outlined,
              title: 'Appeler le support',
              value: SupportContent.supportPhone,
              onTap: () => _launch(
                Uri(
                  scheme: 'tel',
                  path: SupportContent.supportPhone.replaceAll(' ', ''),
                ),
                'le téléphone',
              ),
            ).fadeSlideIn(delay: AppMotion.fast),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Écrivez-nous'),
            const SizedBox(height: AppSpacing.sm),
            NovaCard(
              child: Column(
                children: [
                  NovaTextField(
                    controller: _subject,
                    label: 'Objet',
                    hint: 'Résumez votre demande',
                    icon: Icons.subject_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validators.required(value, field: "L'objet"),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NovaTextField(
                    controller: _message,
                    label: 'Message',
                    hint: 'Décrivez votre demande en détail…',
                    maxLines: 6,
                    minLines: 4,
                    validator: (value) {
                      final base =
                          Validators.required(value, field: 'Le message');
                      if (base != null) return base;
                      if (value!.trim().length < 10) {
                        return 'Détaillez un peu plus votre message.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ).fadeSlideIn(delay: AppMotion.normal),
            const SizedBox(height: AppSpacing.lg),
            NovaButton.primary(
              label: 'Envoyer le message',
              icon: Icons.send_rounded,
              busy: _sending,
              onPressed: _sendMessage,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Votre message ouvrira votre application de messagerie '
              'avec l’adresse du support pré-remplie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded,
              size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}
