import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/address.dart';
import '../../data/repositories/address_repository.dart';
import '../../design/design_system.dart';
import 'add_address_screen.dart';

/// Carnet d'adresses : lister, ajouter, modifier, supprimer, définir défaut.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late Future<List<Address>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Address>> _load() {
    return context.read<AddressRepository>().getAddresses();
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _openEditor([Address? address]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddAddressScreen(existing: address),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _setDefault(Address address) async {
    if (address.isDefault) return;
    await context.read<AddressRepository>().setDefault(address.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('« ${address.label} » est désormais l\'adresse '
              'par défaut.'),
        ),
      );
    _reload();
  }

  Future<void> _confirmDelete(Address address) async {
    final repository = context.read<AddressRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Supprimer l\'adresse ?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'L\'adresse « ${address.label} » sera définitivement supprimée.',
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await repository.removeAddress(address.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Adresse supprimée.'),
        ),
      );
    _reload();
  }

  void _openActions(Address address) {
    showNovaSheet<void>(
      context: context,
      title: address.label,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!address.isDefault)
            _SheetAction(
              icon: Icons.star_rounded,
              label: 'Définir par défaut',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _setDefault(address);
              },
            ),
          _SheetAction(
            icon: Icons.edit_outlined,
            label: 'Modifier l\'adresse',
            onTap: () {
              Navigator.of(sheetContext).pop();
              _openEditor(address);
            },
          ),
          _SheetAction(
            icon: Icons.delete_outline_rounded,
            label: 'Supprimer l\'adresse',
            danger: true,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _confirmDelete(address);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.deepInk,
        foregroundColor: AppColors.lime,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          'Ajouter',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(title: 'Mes adresses'),
          ),
          Expanded(
            child: FutureBuilder<List<Address>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const NovaLoadingView();
                }
                if (snapshot.hasError) {
                  return NovaErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  );
                }
                final addresses = snapshot.requireData;
                if (addresses.isEmpty) {
                  return NovaEmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'Aucune adresse',
                    message: 'Ajoutez une adresse de livraison pour accélérer '
                        'vos prochaines commandes.',
                    actionLabel: 'Ajouter une adresse',
                    onAction: () => _openEditor(),
                  );
                }
                return RefreshIndicator(
                  color: context.colors.textPrimary,
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      return StaggeredEntrance.item(
                        index,
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AddressCard(
                            address: address,
                            onTap: () => _openActions(address),
                            onSetDefault: () => _setDefault(address),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- sub widgets ---------------------------- */

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onSetDefault,
  });

  final Address address;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;

  IconData get _icon {
    switch (address.label.toLowerCase()) {
      case 'domicile':
      case 'maison':
        return Icons.home_outlined;
      case 'bureau':
      case 'travail':
        return Icons.work_outline_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: context.colors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        address.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      const NovaBadge(
                        label: 'Par défaut',
                        tone: NovaBadgeTone.primary,
                        dense: true,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.fullAddress,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                address.phone,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          if (!address.isDefault) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: context.colors.border),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onSetDefault,
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('Définir par défaut'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : context.colors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      ),
      onTap: onTap,
    );
  }
}
