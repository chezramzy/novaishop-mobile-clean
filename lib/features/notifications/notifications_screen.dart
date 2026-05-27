import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../../design/design_system.dart';

/// Centre de notifications : liste paginée, marquage comme lu au clic,
/// action « tout marquer comme lu » et état vide.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<NotificationPage> _future;
  List<AppNotification> _items = const [];
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<NotificationPage> _load() async {
    final page = await context.read<NotificationRepository>().getNotifications(
          pageSize: 50,
        );
    _items = List<AppNotification>.from(page.items);
    return page;
  }

  void _reload() => setState(() => _future = _load());

  int get _unread => _items.where((n) => !n.read).length;

  Future<void> _markOne(AppNotification notification) async {
    if (notification.read) return;
    final index = _items.indexWhere((n) => n.id == notification.id);
    if (index < 0) return;
    setState(() => _items[index] = _items[index].copyWith(read: true));
    try {
      await context.read<NotificationRepository>().markRead(notification.id);
    } catch (_) {
      if (mounted) {
        setState(() => _items[index] = _items[index].copyWith(read: false));
      }
    }
  }

  Future<void> _markAll() async {
    if (_markingAll || _unread == 0) return;
    setState(() => _markingAll = true);
    try {
      await context.read<NotificationRepository>().markAllRead();
      if (!mounted) return;
      setState(() {
        _items = [for (final n in _items) n.copyWith(read: true)];
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.deepInk,
            content: Text('Toutes les notifications sont marquées comme lues.'),
          ),
        );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.danger,
              content: Text('Action impossible. Réessayez plus tard.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<NotificationPage>(
        future: _future,
        builder: (context, snapshot) {
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(
              title: 'Notifications',
              trailing: _unread > 0
                  ? CircleIconButton(
                      icon: Icons.done_all_rounded,
                      tooltip: 'Tout marquer comme lu',
                      onPressed: _markingAll ? null : _markAll,
                    )
                  : null,
            ),
          );

          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              children: [
                header,
                const SizedBox(height: AppSpacing.md),
                const Expanded(child: SkeletonList(itemCount: 6)),
              ],
            );
          }

          if (snapshot.hasError) {
            return Column(
              children: [
                header,
                Expanded(
                  child: NovaErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  ),
                ),
              ],
            );
          }

          if (_items.isEmpty) {
            return Column(
              children: [
                header,
                const Expanded(
                  child: NovaEmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'Aucune notification',
                    message: 'Vos alertes de commandes, promotions et messages '
                        'apparaîtront ici.',
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              header,
              if (_unread > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: NovaBadge(
                      label: '$_unread non lue${_unread > 1 ? 's' : ''}',
                      tone: NovaBadgeTone.danger,
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  color: context.colors.textPrimary,
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      return StaggeredEntrance.item(
                        index,
                        _NotificationTile(
                          notification: _items[index],
                          onTap: () => _markOne(_items[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unread = !notification.read;
    final (icon, tone) = _visualFor(notification.type);
    final (bg, fg) = _toneColors(tone, colors);

    return NovaCard(
      onTap: onTap,
      color: unread ? colors.surfaceMuted : colors.surface,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              unread ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        height: 9,
                        width: 9,
                        margin: const EdgeInsets.only(left: 6, top: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(notification.createdAt),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, NovaBadgeTone) _visualFor(String type) {
    switch (type) {
      case 'order_update':
        return (Icons.receipt_long_rounded, NovaBadgeTone.info);
      case 'delivery_update':
        return (Icons.local_shipping_rounded, NovaBadgeTone.info);
      case 'review_received':
        return (Icons.rate_review_rounded, NovaBadgeTone.warning);
      case 'promotion':
        return (Icons.local_offer_rounded, NovaBadgeTone.success);
      case 'listing_approved':
        return (Icons.check_circle_rounded, NovaBadgeTone.success);
      case 'listing_rejected':
        return (Icons.cancel_rounded, NovaBadgeTone.danger);
      default:
        return (Icons.campaign_rounded, NovaBadgeTone.neutral);
    }
  }

  static (Color, Color) _toneColors(NovaBadgeTone tone, NovaColors colors) {
    switch (tone) {
      case NovaBadgeTone.info:
        return (AppColors.info.withValues(alpha: .14), AppColors.info);
      case NovaBadgeTone.warning:
        return (AppColors.warning.withValues(alpha: .18), AppColors.warning);
      case NovaBadgeTone.success:
        return (AppColors.success.withValues(alpha: .15), AppColors.success);
      case NovaBadgeTone.danger:
        return (AppColors.danger.withValues(alpha: .14), AppColors.danger);
      case NovaBadgeTone.primary:
        return (AppColors.lime, AppColors.ink);
      case NovaBadgeTone.neutral:
        return (colors.surfaceMuted, colors.textPrimary);
    }
  }

  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final now = DateTime.now();
    final date = parsed.toLocal();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    }
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}
