import 'package:flutter/material.dart';

import '../../design/design_system.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: NovaEmptyState(
        icon: Icons.credit_card_off_outlined,
        title: 'Paiement indisponible',
        message: 'Les moyens de paiement seront actives quand le prestataire '
            'de paiement reel sera branche.',
        actionLabel: 'Retour',
        onAction: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
