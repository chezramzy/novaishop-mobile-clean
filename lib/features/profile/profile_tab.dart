import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/auth_user.dart';
import '../../data/repositories/notification_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';

/// L'onglet « Profil » : en-tête utilisateur, statistiques rapides,
/// raccourcis vers les espaces dédiés, menu de compte et déconnexion.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final count =
          await context.read<NotificationRepository>().getUnreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {
      // Le badge reste silencieux si le compteur est indisponible.
    }
  }

  Future<void> _open(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) _loadUnread();
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final isAdmin = user?.email.toLowerCase() == 'blorayworld@gmail.com';

    return SoftGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mon profil',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _NotificationBell(
                count: _unread,
                onTap: () => _open(RouteNames.notifications),
              ),
            ],
          ).fadeSlideIn(),
          const SizedBox(height: AppSpacing.lg),
          if (user != null) ...[
            _ProfileHeaderCard(
              user: user,
              onEdit: () => _open(RouteNames.editProfile),
            ).fadeSlideIn(delay: AppMotion.fast),
            const SizedBox(height: AppSpacing.md),
            _QuickStats(user: user).fadeSlideIn(delay: AppMotion.normal),
            if (user.role.isSeller) ...[
              const SizedBox(height: AppSpacing.md),
              _SpaceCard(
                title: 'Espace partenaire',
                subtitle: 'Gerez vos produits, stocks et validations',
                icon: Icons.inventory_2_rounded,
                onTap: () => _open(RouteNames.partnerHub),
              ).fadeSlideIn(delay: AppMotion.normal),
            ],
            if (user.role.isDriver) ...[
              const SizedBox(height: AppSpacing.md),
              _SpaceCard(
                title: 'Espace livreur',
                subtitle: 'Suivez vos livraisons et vos gains',
                icon: Icons.local_shipping_rounded,
                onTap: () => _open(RouteNames.driverHome),
              ).fadeSlideIn(delay: AppMotion.normal),
            ],
          ] else
            const _SignedOutCard(),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Mon compte'),
          const SizedBox(height: AppSpacing.sm),
          ..._menuGroup([
            _MenuItem(
              icon: Icons.receipt_long_rounded,
              label: 'Mes commandes',
              onTap: () => _open(RouteNames.orders),
            ),
            _MenuItem(
              icon: Icons.favorite_rounded,
              label: 'Favoris',
              onTap: () => _open(RouteNames.wishlist),
            ),
            _MenuItem(
              icon: Icons.location_on_rounded,
              label: 'Adresses',
              onTap: () => _open(RouteNames.addresses),
            ),
            _MenuItem(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              badge: _unread > 0 ? '$_unread' : null,
              onTap: () => _open(RouteNames.notifications),
            ),
            if (isAdmin)
              _MenuItem(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Administration',
                onTap: () => _open(RouteNames.admin),
              ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Préférences & aide'),
          const SizedBox(height: AppSpacing.sm),
          ..._menuGroup([
            _MenuItem(
              icon: Icons.settings_rounded,
              label: 'Réglages',
              onTap: () => _open(RouteNames.settings),
            ),
            _MenuItem(
              icon: Icons.help_center_rounded,
              label: 'Aide & support',
              onTap: () => _open(RouteNames.support),
            ),
          ]),
          if (user != null) ...[
            const SizedBox(height: AppSpacing.xl),
            NovaButton.ghost(
              label: 'Déconnexion',
              icon: Icons.logout_rounded,
              onPressed: _confirmLogout,
            ).fadeSlideIn(delay: AppMotion.slow),
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

  List<Widget> _menuGroup(List<_MenuItem> items) {
    return [
      for (var i = 0; i < items.length; i++)
        StaggeredEntrance.item(
          i,
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: items[i],
          ),
        ),
    ];
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ).popIn(),
          ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.user, required this.onEdit});

  final AuthUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      color: AppColors.deepInk,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _Avatar(user: user, radius: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName.isEmpty
                            ? 'Utilisateur NovAiShop'
                            : user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (user.emailVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded,
                          size: 16, color: AppColors.lime),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                NovaBadge(
                  label: user.role.label,
                  tone: NovaBadgeTone.primary,
                  icon: user.role.icon,
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: Icons.edit_rounded,
            backgroundColor: AppColors.lime,
            tooltip: 'Modifier le profil',
            size: 40,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.radius});

  final AuthUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lime,
      backgroundImage:
          user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
      child: user.avatarUrl == null
          ? Text(
              user.initials,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.62,
              ),
            )
          : null,
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final phone =
        user.phone.trim().isEmpty ? 'Non renseigné' : user.phone.trim();
    return NovaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.badge_outlined,
              label: 'Type de compte',
              value: user.role.isSeller
                  ? 'Partenaire'
                  : user.role.isDriver
                      ? 'Livreur'
                      : 'Acheteur',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatTile(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: phone,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: context.colors.textPrimary),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: context.colors.border,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      color: AppColors.lime,
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.deepInk,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.lime),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.ink, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: AppColors.ink),
        ],
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard();

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Column(
        children: [
          const Icon(Icons.person_off_outlined,
              size: 40, color: AppColors.muted),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Aucune session active',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Connectez-vous pour accéder à votre profil.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          NovaButton.primary(
            label: 'Se connecter',
            onPressed: () => Navigator.of(context).pushNamed(RouteNames.signIn),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

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
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 19, color: context.colors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          if (badge != null) ...[
            NovaBadge(label: badge!, tone: NovaBadgeTone.danger, dense: true),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
