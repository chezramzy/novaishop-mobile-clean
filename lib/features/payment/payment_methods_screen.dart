import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design_system.dart';
import 'payment_method.dart';

/// Manage the device's mock payment methods: list, add, set default and
/// remove. Persisted locally (there is no payment-methods API).
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

enum _Phase { loading, ready, error }

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _store = PaymentMethodStore.instance;

  _Phase _phase = _Phase.loading;
  List<PaymentMethod> _methods = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final methods = await _store.getMethods();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _phase = _Phase.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.error);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final created = await showNovaSheet<PaymentMethod>(
      context: context,
      title: 'Nouveau moyen de paiement',
      builder: (sheetContext) => const _AddMethodForm(),
    );
    if (created == null) return;
    final methods = await _store.add(created);
    if (!mounted) return;
    setState(() => _methods = methods);
    _toast('${created.brand.label} ajouté.');
  }

  Future<void> _setDefault(PaymentMethod method) async {
    if (method.isDefault) return;
    final methods = await _store.setDefault(method.id);
    if (!mounted) return;
    setState(() => _methods = methods);
    _toast('${method.brand.label} défini par défaut.');
  }

  Future<void> _remove(PaymentMethod method) async {
    final confirmed = await showNovaSheet<bool>(
      context: context,
      title: 'Supprimer ce moyen de paiement ?',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${method.brand.label} · ${method.masked} sera retiré '
            'de cet appareil.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          NovaButton.primary(
            label: 'Supprimer',
            icon: Icons.delete_outline_rounded,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.xs),
          NovaButton.ghost(
            label: 'Annuler',
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final methods = await _store.remove(method.id);
    if (!mounted) return;
    setState(() => _methods = methods);
    _toast('Moyen de paiement supprimé.');
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      floatingActionButton: _phase == _Phase.ready && _methods.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: AppColors.deepInk,
              foregroundColor: AppColors.lime,
              icon: const Icon(Icons.add_card_outlined),
              label: const Text(
                'Ajouter',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: ScreenHeader(title: 'Moyens de paiement'),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
        return const NovaLoadingView(label: 'Chargement…');
      case _Phase.error:
        return NovaErrorState(
          message: 'Impossible de charger vos moyens de paiement.',
          onRetry: _load,
        );
      case _Phase.ready:
        if (_methods.isEmpty) {
          return NovaEmptyState(
            icon: Icons.credit_card_off_outlined,
            title: 'Aucun moyen de paiement',
            message: 'Ajoutez une carte ou un portefeuille pour régler '
                'vos commandes plus rapidement.',
            actionLabel: 'Ajouter un moyen de paiement',
            onAction: _add,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl + AppSpacing.lg,
          ),
          itemCount: _methods.length,
          itemBuilder: (context, index) {
            final method = _methods[index];
            return _MethodCard(
              method: method,
              onSetDefault: () => _setDefault(method),
              onRemove: () => _remove(method),
            ).fadeSlideIn(delay: AppMotion.stagger * index);
          },
        );
    }
  }
}

/* ------------------------------- method card ----------------------------- */

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.onSetDefault,
    required this.onRemove,
  });

  final PaymentMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: method.brand.tintOf(context.colors),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  method.brand.icon,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          method.brand.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        if (method.isDefault) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const NovaBadge(
                            label: 'Par défaut',
                            tone: NovaBadgeTone.primary,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.masked,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      method.holder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Supprimer',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          if (!method.isDefault) ...[
            const Divider(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: onSetDefault,
              icon: const Icon(Icons.star_outline_rounded, size: 18),
              label: const Text('Définir par défaut'),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textPrimary,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ------------------------------- add form -------------------------------- */

class _AddMethodForm extends StatefulWidget {
  const _AddMethodForm();

  @override
  State<_AddMethodForm> createState() => _AddMethodFormState();
}

class _AddMethodFormState extends State<_AddMethodForm> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();

  PaymentBrand _brand = PaymentBrand.visa;

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  String get _numberLabel =>
      _brand.isCard ? 'Numéro de carte' : 'Référence du compte';

  String get _numberHint => _brand.isCard
      ? '4242 4242 4242 4242'
      : 'Identifiant ou numéro de téléphone';

  String? _validateNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) {
      return _brand.isCard
          ? 'Saisissez un numéro de carte valide.'
          : 'Saisissez une référence valide.';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final digits = _numberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final last4 = digits.substring(digits.length - 4);
    final method = PaymentMethod(
      id: 'pm-${DateTime.now().microsecondsSinceEpoch}',
      brand: _brand,
      holder: _holderController.text.trim(),
      last4: last4,
    );
    Navigator.of(context).pop(method);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Type',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final brand in PaymentBrand.values)
                NovaChip(
                  label: brand.label,
                  icon: brand.icon,
                  selected: brand == _brand,
                  onTap: () => setState(() => _brand = brand),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          NovaTextField(
            controller: _holderController,
            label: 'Titulaire',
            hint: 'Nom du titulaire',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: (value) => Validators.name(value, field: 'Le titulaire'),
          ),
          const SizedBox(height: AppSpacing.sm),
          NovaTextField(
            controller: _numberController,
            label: _numberLabel,
            hint: _numberHint,
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              LengthLimitingTextInputFormatter(19),
            ],
            validator: _validateNumber,
          ),
          const SizedBox(height: AppSpacing.lg),
          NovaButton.primary(
            label: 'Enregistrer',
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Données fictives — aucune information bancaire réelle '
            'n’est collectée.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
