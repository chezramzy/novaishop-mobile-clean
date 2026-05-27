import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/coupon_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'widgets/seller_widgets.dart';

/// Lets a seller create a discount coupon via [CouponRepository].
class CreateCouponScreen extends StatefulWidget {
  const CreateCouponScreen({super.key});

  @override
  State<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends State<CreateCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _minOrder = TextEditingController();
  final _maxUses = TextEditingController();

  String _discountType = 'percentage';
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _minOrder.dispose();
    _maxUses.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.').replaceAll(' ', '');
    return double.tryParse(normalized);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_validFrom ?? now)
        : (_validTo ?? _validFrom ?? now.add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _validFrom = picked;
      } else {
        _validTo = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final value = _parseAmount(_value.text);
    if (value == null || value <= 0) {
      showSellerSnack(context, 'Saisissez une valeur valide.', error: true);
      return;
    }
    if (_discountType == 'percentage' && value > 100) {
      showSellerSnack(
        context,
        'Le pourcentage ne peut pas dépasser 100 %.',
        error: true,
      );
      return;
    }
    if (_validFrom != null &&
        _validTo != null &&
        _validTo!.isBefore(_validFrom!)) {
      showSellerSnack(
        context,
        'La date de fin doit suivre la date de début.',
        error: true,
      );
      return;
    }

    final minOrder = _parseAmount(_minOrder.text);
    final maxUses = int.tryParse(_maxUses.text.trim());

    setState(() => _busy = true);
    try {
      await context.read<CouponRepository>().createCoupon(
            code: _code.text,
            discountType: _discountType,
            discountValue: value,
            minOrderAmount: minOrder != null && minOrder > 0 ? minOrder : null,
            maxUses: maxUses != null && maxUses > 0 ? maxUses : null,
            validFrom: _validFrom?.toIso8601String(),
            validTo: _validTo?.toIso8601String(),
          );
      if (!mounted) return;
      showSellerSnack(context, 'Coupon créé.');
      Navigator.of(context).pop(true);
    } on RepositoryException catch (error) {
      if (mounted) showSellerSnack(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showSellerSnack(
          context,
          'Création impossible. Réessayez.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Choisir une date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPercentage = _discountType == 'percentage';
    return SoftGradientScaffold(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: StaggeredEntrance.all([
            const ScreenHeader(title: 'Nouveau coupon'),
            const SizedBox(height: AppSpacing.md),
            const SellerInfoBanner(
              icon: Icons.local_offer_outlined,
              message: 'Créez un code de réduction que vos clients pourront '
                  'appliquer au panier.',
            ),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _code,
              label: 'Code du coupon',
              hint: 'Ex. BIENVENUE10',
              icon: Icons.confirmation_number_outlined,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                UpperCaseTextFormatter(),
              ],
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.length < 3) {
                  return 'Le code doit contenir au moins 3 caractères.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Type de remise',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _DiscountTypeTile(
                    label: 'Pourcentage',
                    icon: Icons.percent_rounded,
                    selected: isPercentage,
                    onTap: () => setState(() => _discountType = 'percentage'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _DiscountTypeTile(
                    label: 'Montant fixe',
                    icon: Icons.euro_rounded,
                    selected: !isPercentage,
                    onTap: () => setState(() => _discountType = 'fixed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _value,
              label: isPercentage
                  ? 'Pourcentage de réduction (%)'
                  : 'Montant de la réduction (FCFA)',
              hint: isPercentage ? '10' : '5,00',
              icon: isPercentage ? Icons.percent_rounded : Icons.sell_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (value) {
                final parsed = _parseAmount(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Valeur invalide.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _minOrder,
              label: 'Montant minimum de commande (FCFA, facultatif)',
              hint: '0,00',
              icon: Icons.shopping_cart_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            NovaTextField(
              controller: _maxUses,
              label: 'Nombre d\'utilisations max. (facultatif)',
              hint: 'Illimité si vide',
              icon: Icons.repeat_rounded,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Valable du',
                    value: _dateLabel(_validFrom),
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _DateField(
                    label: 'Valable jusqu\'au',
                    value: _dateLabel(_validTo),
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            NovaButton.primary(
              label: 'Créer le coupon',
              icon: Icons.check_rounded,
              busy: _busy,
              onPressed: _submit,
            ),
          ]),
        ),
      ),
    );
  }
}

/// Forces text-field input to upper case.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _DiscountTypeTile extends StatelessWidget {
  const _DiscountTypeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.lime.withValues(alpha: .22)
          : context.colors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.lime : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: context.colors.textPrimary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
