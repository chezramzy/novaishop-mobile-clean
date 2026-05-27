import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/address.dart';
import '../../data/repositories/address_repository.dart';
import '../../design/design_system.dart';

/// Formulaire d'ajout ou de modification d'une adresse de livraison.
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({this.existing, super.key});

  /// Adresse à modifier, ou `null` pour une création.
  final Address? existing;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _line;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _phone;

  late bool _isDefault;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  static const _quickLabels = ['Domicile', 'Bureau', 'Autre'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? '');
    _line = TextEditingController(text: existing?.line ?? '');
    _city = TextEditingController(text: existing?.city ?? '');
    _country = TextEditingController(text: existing?.country ?? 'France');
    _phone = TextEditingController(text: existing?.phone ?? '');
    _isDefault = existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _line.dispose();
    _city.dispose();
    _country.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repository = context.read<AddressRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final address = Address(
      id: widget.existing?.id ??
          'addr-${DateTime.now().millisecondsSinceEpoch}',
      label: _label.text.trim(),
      line: _line.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim().isEmpty ? 'France' : _country.text.trim(),
      phone: _phone.text.trim(),
      isDefault: _isDefault,
      mapImageUrl: widget.existing?.mapImageUrl,
    );

    try {
      if (_isEditing) {
        await repository.updateAddress(address);
      } else {
        await repository.addAddress(address);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              _isEditing ? 'Adresse mise à jour.' : 'Adresse ajoutée.',
            ),
          ),
        );
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString()),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: StaggeredEntrance.all([
            ScreenHeader(
              title: _isEditing ? 'Modifier l\'adresse' : 'Ajouter une adresse',
            ),
            const SizedBox(height: 22),

            // ---------- quick labels ----------
            Text(
              'Type d\'adresse',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in _quickLabels)
                  NovaChip(
                    label: label,
                    selected:
                        _label.text.trim().toLowerCase() == label.toLowerCase(),
                    onTap: () => setState(() => _label.text = label),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            NovaTextField(
              controller: _label,
              label: 'Libellé',
              hint: 'Domicile, Bureau, Chez Marie...',
              icon: Icons.bookmark_outline_rounded,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  Validators.required(value, field: 'Le libellé'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            NovaTextField(
              controller: _line,
              label: 'Adresse complète',
              hint: '12 rue des Lilas, 75011',
              icon: Icons.home_outlined,
              maxLines: 2,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  Validators.required(value, field: 'L\'adresse'),
            ),
            const SizedBox(height: 16),

            NovaTextField(
              controller: _city,
              label: 'Ville',
              hint: 'Paris',
              icon: Icons.location_city_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  Validators.required(value, field: 'La ville'),
            ),
            const SizedBox(height: 16),

            NovaTextField(
              controller: _country,
              label: 'Pays',
              hint: 'France',
              icon: Icons.public_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            NovaTextField(
              controller: _phone,
              label: 'Téléphone',
              hint: '+33 6 12 34 56 78',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (value) => Validators.phone(value),
            ),
            const SizedBox(height: 16),

            // ---------- default toggle ----------
            NovaCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.deepInk,
                activeTrackColor: AppColors.lime,
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                title: const Text(
                  'Adresse par défaut',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Utilisée automatiquement lors du paiement.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            NovaButton.primary(
              label: _isEditing
                  ? 'Enregistrer les modifications'
                  : 'Enregistrer l\'adresse',
              icon: Icons.check_rounded,
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ),
      ),
    );
  }
}
