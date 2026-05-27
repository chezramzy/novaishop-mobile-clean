import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/nova_colors.dart';

/// The colour intent of a [NovaBadge].
enum NovaBadgeTone { neutral, primary, success, warning, danger, info }

/// A small pill label for tags, counts and statuses.
class NovaBadge extends StatelessWidget {
  const NovaBadge({
    required this.label,
    this.tone = NovaBadgeTone.neutral,
    this.icon,
    this.dense = false,
    super.key,
  });

  final String label;
  final NovaBadgeTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsFor(tone, context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 3 : 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 12 : 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: dense ? 10 : 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color, Color) _colorsFor(NovaBadgeTone tone, BuildContext context) {
    switch (tone) {
      case NovaBadgeTone.neutral:
        return (context.colors.surfaceMuted, context.colors.textPrimary);
      case NovaBadgeTone.primary:
        return (AppColors.lime, AppColors.ink);
      case NovaBadgeTone.success:
        return (AppColors.success.withValues(alpha: .15), AppColors.success);
      case NovaBadgeTone.warning:
        return (AppColors.warning.withValues(alpha: .18), AppColors.warning);
      case NovaBadgeTone.danger:
        return (AppColors.danger.withValues(alpha: .14), AppColors.danger);
      case NovaBadgeTone.info:
        return (AppColors.info.withValues(alpha: .14), AppColors.info);
    }
  }
}

/// A badge that maps a domain status string to a French label and tone.
///
/// Handles listing, order, payment, delivery, KYC and driver statuses so
/// every feature renders statuses consistently.
class NovaStatusBadge extends StatelessWidget {
  const NovaStatusBadge({required this.status, this.dense = false, super.key});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = _resolve(status);
    return NovaBadge(label: label, tone: tone, dense: dense);
  }

  static (String, NovaBadgeTone) _resolve(String status) {
    switch (status) {
      // Listing statuses.
      case 'published':
        return ('En ligne', NovaBadgeTone.success);
      case 'pending_review':
        return ('En validation', NovaBadgeTone.warning);
      case 'draft':
        return ('Brouillon', NovaBadgeTone.neutral);
      case 'rejected':
        return ('Refusé', NovaBadgeTone.danger);
      case 'archived':
        return ('Archivé', NovaBadgeTone.neutral);

      // Order statuses.
      case 'pending':
        return ('En attente', NovaBadgeTone.warning);
      case 'paid':
        return ('Payée', NovaBadgeTone.info);
      case 'processing':
        return ('En préparation', NovaBadgeTone.info);
      case 'shipped':
        return ('Expédiée', NovaBadgeTone.info);
      case 'delivered':
        return ('Livrée', NovaBadgeTone.success);
      case 'refunded':
        return ('Remboursée', NovaBadgeTone.neutral);
      case 'cancelled':
        return ('Annulée', NovaBadgeTone.danger);

      // Payment statuses.
      case 'requires_payment_method':
        return ('Paiement requis', NovaBadgeTone.warning);
      case 'requires_confirmation':
        return ('À confirmer', NovaBadgeTone.warning);
      case 'succeeded':
        return ('Réussi', NovaBadgeTone.success);
      case 'failed':
        return ('Échoué', NovaBadgeTone.danger);

      // Delivery statuses.
      case 'assigned':
        return ('Assignée', NovaBadgeTone.warning);
      case 'accepted':
        return ('Acceptée', NovaBadgeTone.info);
      case 'picked_up':
        return ('Récupérée', NovaBadgeTone.info);
      case 'in_transit':
        return ('En route', NovaBadgeTone.info);

      // KYC / vendor statuses.
      case 'submitted':
        return ('Soumis', NovaBadgeTone.warning);
      case 'under_review':
        return ('En revue', NovaBadgeTone.warning);
      case 'approved':
        return ('Approuvé', NovaBadgeTone.success);

      // Driver statuses.
      case 'available':
        return ('Disponible', NovaBadgeTone.success);
      case 'busy':
        return ('Occupé', NovaBadgeTone.warning);
      case 'offline':
        return ('Hors ligne', NovaBadgeTone.neutral);

      default:
        return (status, NovaBadgeTone.neutral);
    }
  }
}
