import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router/route_names.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'settings_preferences.dart';
import 'theme_controller.dart';

/// Adresse de contact du support NovAiShop.
const _supportEmail = 'support@novaishop.com';

/// Écran « Réglages » : préférences de notifications, apparence, langue
/// et gestion du compte (déconnexion, suppression).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await SettingsPreferences.load();
    if (mounted) setState(() => _state = state);
  }

  Future<void> _update(
    SettingsState next,
    Future<void> Function() persist,
  ) async {
    setState(() => _state = next);
    await persist();
  }

  /// Ouvre le sélecteur de thème (Clair / Sombre / Système).
  void _chooseTheme() {
    final controller = context.read<ThemeController>();
    showNovaSheet<void>(
      context: context,
      title: 'Thème de l\'application',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final mode in ThemeMode.values)
            _ThemeOption(
              mode: mode,
              selected: controller.mode == mode,
              onTap: () {
                controller.setMode(mode);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  void _info(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.deepInk,
          content: Text(message),
        ),
      );
  }

  /// Prépare une demande de suppression de compte (e-mail au support) puis
  /// déconnecte l'utilisateur. La suppression définitive est traitée par le
  /// support conformément aux délais légaux.
  Future<void> _requestAccountDeletion() async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final user = auth.user;
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject='
          '${Uri.encodeComponent('Demande de suppression de compte')}'
          '&body=${Uri.encodeComponent(
        'Bonjour,\n\n'
        'Je demande la suppression définitive de mon compte NovAiShop '
        'et de mes données personnelles.\n\n'
        'Compte : ${user?.email ?? ''}\n'
        'Identifiant : ${user?.id ?? ''}\n\n'
        'Merci de confirmer la prise en compte de cette demande.',
      )}',
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (launched) {
      await auth.signOut();
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.deepInk,
            content: Text(
              'Écrivez-nous à $_supportEmail pour supprimer votre compte.',
            ),
          ),
        );
    }
  }

  void _confirmLogout() {
    showNovaSheet<void>(
      context: context,
      title: 'Déconnexion',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte ?',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: NovaButton.ghost(
                  label: 'Annuler',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NovaButton.secondary(
                  label: 'Déconnexion',
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.read<AuthController>().signOut();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showNovaSheet<void>(
      context: context,
      title: 'Supprimer le compte',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NovaCard(
            color: AppColors.blush,
            elevated: false,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Cette action est irréversible. Toutes vos données, '
                    'commandes et favoris seront définitivement supprimés.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          NovaButton.ghost(
            label: 'Annuler',
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
          const SizedBox(height: AppSpacing.xs),
          NovaButton.secondary(
            label: 'Demander la suppression',
            icon: Icons.delete_outline_rounded,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _requestAccountDeletion();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final state = _state;

    return SoftGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const ScreenHeader(title: 'Réglages'),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Notifications'),
          const SizedBox(height: AppSpacing.sm),
          if (state == null)
            const NovaCard(
              child: SizedBox(
                height: 120,
                child: NovaLoadingView(),
              ),
            ).fadeSlideIn()
          else
            NovaCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.receipt_long_rounded,
                    title: 'Suivi des commandes',
                    subtitle: 'Statut et mises à jour de vos commandes',
                    value: state.orderUpdates,
                    onChanged: (v) => _update(
                      state.copyWith(orderUpdates: v),
                      () => SettingsPreferences.setOrderUpdates(v),
                    ),
                  ),
                  const _RowDivider(),
                  _ToggleRow(
                    icon: Icons.local_shipping_rounded,
                    title: 'Livraisons',
                    subtitle: 'Alertes de progression des livraisons',
                    value: state.deliveryUpdates,
                    onChanged: (v) => _update(
                      state.copyWith(deliveryUpdates: v),
                      () => SettingsPreferences.setDeliveryUpdates(v),
                    ),
                  ),
                  const _RowDivider(),
                  _ToggleRow(
                    icon: Icons.local_offer_rounded,
                    title: 'Promotions',
                    subtitle: 'Offres et ventes flash personnalisées',
                    value: state.promotions,
                    onChanged: (v) => _update(
                      state.copyWith(promotions: v),
                      () => SettingsPreferences.setPromotions(v),
                    ),
                  ),
                  const _RowDivider(),
                  _ToggleRow(
                    icon: Icons.mark_email_unread_rounded,
                    title: 'Résumé par e-mail',
                    subtitle: 'Recevez un récapitulatif hebdomadaire',
                    value: state.emailDigest,
                    onChanged: (v) => _update(
                      state.copyWith(emailDigest: v),
                      () => SettingsPreferences.setEmailDigest(v),
                    ),
                  ),
                  const _RowDivider(),
                  _ToggleRow(
                    icon: Icons.volume_up_rounded,
                    title: 'Son & vibration',
                    subtitle: 'Alerte sonore à la réception',
                    value: state.sound,
                    onChanged: (v) => _update(
                      state.copyWith(sound: v),
                      () => SettingsPreferences.setSound(v),
                    ),
                  ),
                ],
              ),
            ).fadeSlideIn(),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Apparence & langue'),
          const SizedBox(height: AppSpacing.sm),
          NovaCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Column(
              children: [
                _NavRow(
                  icon: Icons.palette_outlined,
                  title: 'Thème',
                  trailing: context.watch<ThemeController>().label,
                  onTap: _chooseTheme,
                ),
                const _RowDivider(),
                _NavRow(
                  icon: Icons.language_rounded,
                  title: 'Langue',
                  trailing: 'Français',
                  onTap: () => _info(
                    'NovAiShop est proposé en français.',
                  ),
                ),
              ],
            ),
          ).fadeSlideIn(delay: AppMotion.fast),
          const SizedBox(height: AppSpacing.xs),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              "L'application est actuellement disponible en français.",
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Compte'),
          const SizedBox(height: AppSpacing.sm),
          NovaCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Column(
              children: [
                _NavRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Modifier le profil',
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.editProfile),
                ),
                const _RowDivider(),
                _NavRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Changer le mot de passe',
                  onTap: () => Navigator.of(context)
                      .pushNamed(RouteNames.changePassword),
                ),
                const _RowDivider(),
                _NavRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Aide & support',
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.support),
                ),
              ],
            ),
          ).fadeSlideIn(delay: AppMotion.normal),
          const SizedBox(height: AppSpacing.lg),
          if (user != null) ...[
            NovaButton.ghost(
              label: 'Déconnexion',
              icon: Icons.logout_rounded,
              onPressed: _confirmLogout,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.danger),
              label: const Text(
                'Supprimer mon compte',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Center(
            child: Text(
              'NovAiShop · version 1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.textPrimary),
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
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.ink,
            activeTrackColor: AppColors.lime,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: context.colors.border,
      indent: 4,
      endIndent: 4,
    );
  }
}

/// Une option du sélecteur de thème affichée dans la feuille modale.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  ({IconData icon, String subtitle}) get _details {
    switch (mode) {
      case ThemeMode.light:
        return (
          icon: Icons.light_mode_outlined,
          subtitle: 'Fond clair en toutes circonstances',
        );
      case ThemeMode.dark:
        return (
          icon: Icons.dark_mode_outlined,
          subtitle: 'Fond sombre, plus reposant le soir',
        );
      case ThemeMode.system:
        return (
          icon: Icons.brightness_auto_outlined,
          subtitle: 'Suit le réglage de votre appareil',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final details = _details;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: NovaCard(
        onTap: onTap,
        elevated: false,
        color: selected ? colors.surfaceMuted : colors.surface,
        border: Border.all(
          color: selected ? AppColors.lime : colors.border,
          width: selected ? 1.6 : 1,
        ),
        child: Row(
          children: [
            Icon(details.icon, size: 22, color: colors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ThemeController.labelFor(mode),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details.subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.success : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
