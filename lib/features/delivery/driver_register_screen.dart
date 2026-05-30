import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/delivery_driver.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'driver_format.dart';

/// Driver registration form: collects identity, contact and vehicle
/// details, then calls `DriverRepository.register(...)`.
class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();

  static const _vehicles = ['moto', 'car', 'bicycle', 'van'];
  String _vehicleType = 'moto';
  bool _busy = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final driver = await context.read<DriverRepository>().register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            phone: _phone.text,
            vehicleType: _vehicleType,
            licensePlate: _plate.text.trim().isEmpty ? null : _plate.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bienvenue ! Votre profil livreur est créé.'),
        ),
      );
      Navigator.of(context).pop(driver);
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue. Veuillez réessayer.'),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            const ScreenHeader(title: 'Devenir livreur'),
            const SizedBox(height: 20),
            Center(
              child: Container(
                height: 84,
                width: 84,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  size: 42,
                  color: AppColors.ink,
                ),
              ).popIn(),
            ),
            const SizedBox(height: 16),
            Text(
              'Rejoignez nos livreurs',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ).fadeSlideIn(),
            const SizedBox(height: 8),
            Text(
              'Renseignez vos informations pour commencer à livrer les '
              'commandes NovaShop et générer des revenus.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted,
            ).fadeSlideIn(delay: AppMotion.fast),
            const SizedBox(height: 24),
            NovaTextField(
              controller: _firstName,
              label: 'Prénom',
              hint: 'Votre prénom',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.name(v, field: 'Le prénom'),
            ),
            const SizedBox(height: 16),
            NovaTextField(
              controller: _lastName,
              label: 'Nom',
              hint: 'Votre nom',
              icon: Icons.badge_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.name(v, field: 'Le nom'),
            ),
            const SizedBox(height: 16),
            NovaTextField(
              controller: _phone,
              label: 'Téléphone',
              hint: '+225 07 00 00 00 00',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            Text(
              'Type de véhicule',
              style: AppTypography.subtitle,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final vehicle in _vehicles)
                  NovaChip(
                    label: DeliveryFormat.vehicleLabel(vehicle),
                    icon: DeliveryFormat.vehicleIcon(vehicle),
                    selected: _vehicleType == vehicle,
                    onTap: () => setState(() => _vehicleType = vehicle),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            NovaTextField(
              controller: _plate,
              label: _vehicleType == 'bicycle'
                  ? 'Plaque (facultatif)'
                  : 'Plaque d\'immatriculation',
              hint: 'Ex. AB-123-CD',
              icon: Icons.confirmation_number_outlined,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              helperText: _vehicleType == 'bicycle'
                  ? 'Non requise pour un vélo.'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            NovaButton.primary(
              label: 'Créer mon profil livreur',
              icon: Icons.check_circle_outline_rounded,
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Text(
              'En continuant, vous acceptez les conditions du programme '
              'de livraison NovaShop.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience: the registration result type returned via [Navigator.pop].
typedef DriverRegistrationResult = DeliveryDriver;
