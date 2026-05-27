import 'package:flutter/material.dart';

import '../../design/design_system.dart';

/// Shared helpers for the delivery feature: labels, icons and date
/// formatting, all in French.
class DeliveryFormat {
  const DeliveryFormat._();

  /// French label for a delivery status.
  static String statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assignée';
      case 'accepted':
        return 'Acceptée';
      case 'picked_up':
        return 'Récupérée';
      case 'in_transit':
        return 'En route';
      case 'delivered':
        return 'Livrée';
      case 'failed':
        return 'Échouée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  /// French label for a vehicle type.
  static String vehicleLabel(String type) {
    switch (type) {
      case 'moto':
        return 'Moto';
      case 'car':
        return 'Voiture';
      case 'bicycle':
        return 'Vélo';
      case 'van':
        return 'Camionnette';
      default:
        return type;
    }
  }

  /// Icon for a vehicle type.
  static IconData vehicleIcon(String type) {
    switch (type) {
      case 'moto':
        return Icons.two_wheeler_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'bicycle':
        return Icons.pedal_bike_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }

  /// French label for a payout status.
  static String payoutStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Versé';
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En cours';
      case 'failed':
        return 'Échoué';
      default:
        return status;
    }
  }

  /// Tone for a payout status badge.
  static NovaBadgeTone payoutTone(String status) {
    switch (status) {
      case 'paid':
        return NovaBadgeTone.success;
      case 'pending':
        return NovaBadgeTone.warning;
      case 'processing':
        return NovaBadgeTone.info;
      case 'failed':
        return NovaBadgeTone.danger;
      default:
        return NovaBadgeTone.neutral;
    }
  }

  /// Parses an ISO date string and renders it as `21 mai 2026`, or returns
  /// the raw string when it cannot be parsed.
  static String date(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.day} ${_month(parsed.month)} ${parsed.year}';
  }

  /// Renders a date string as a short `21 mai` label.
  static String shortDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.day} ${_month(parsed.month)}';
  }

  /// Renders a date string as `21 mai · 14:30`.
  static String dateTime(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day} ${_month(parsed.month)} · $hh:$mm';
  }

  /// Short weekday letter for a date string (`L`, `M`, `M`, `J`, `V`, `S`,
  /// `D`).
  static String weekdayLetter(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    const letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return letters[(parsed.weekday - 1) % 7];
  }

  static String _month(int month) {
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return months[(month - 1) % 12];
  }
}
