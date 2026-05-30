import 'package:flutter/material.dart';

import '../../data/models/order.dart';

/// Onglets de la liste des commandes.
enum OrderTab {
  enCours('En cours'),
  expediees('Expédiées'),
  livrees('Livrées'),
  annulees('Annulées');

  const OrderTab(this.label);

  final String label;

  /// Détermine si une commande au [status] donné appartient à cet onglet.
  bool matches(String status) {
    final normalized = status.toLowerCase();
    switch (this) {
      case OrderTab.enCours:
        return const {'pending', 'paid', 'processing'}.contains(normalized);
      case OrderTab.expediees:
        return normalized == 'shipped';
      case OrderTab.livrees:
        return normalized == 'delivered';
      case OrderTab.annulees:
        return const {'cancelled', 'refunded'}.contains(normalized);
    }
  }

  String get emptyTitle {
    switch (this) {
      case OrderTab.enCours:
        return 'Aucune commande en cours';
      case OrderTab.expediees:
        return 'Aucune commande expédiée';
      case OrderTab.livrees:
        return 'Aucune commande livrée';
      case OrderTab.annulees:
        return 'Aucune commande annulée';
    }
  }

  String get emptyMessage {
    switch (this) {
      case OrderTab.enCours:
        return 'Vos commandes en préparation apparaîtront ici.';
      case OrderTab.expediees:
        return 'Vos colis en route s\'afficheront ici.';
      case OrderTab.livrees:
        return 'Retrouvez ici vos commandes déjà livrées.';
      case OrderTab.annulees:
        return 'Vos commandes annulées ou remboursées seront listées ici.';
    }
  }
}

/// Une étape du parcours de livraison.
class OrderStep {
  const OrderStep({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

/// Outils partagés autour du statut d'une commande.
class OrderStatusX {
  const OrderStatusX._();

  /// Les cinq étapes du suivi de livraison, dans l'ordre.
  static const steps = <OrderStep>[
    OrderStep(
      label: 'Commande passée',
      description: 'Nous avons bien reçu votre commande.',
      icon: Icons.receipt_long_outlined,
    ),
    OrderStep(
      label: 'Paiement confirmé',
      description: 'Votre paiement a été validé.',
      icon: Icons.payments_outlined,
    ),
    OrderStep(
      label: 'En préparation',
      description: 'NovaShop prépare votre colis.',
      icon: Icons.inventory_2_outlined,
    ),
    OrderStep(
      label: 'Expédiée',
      description: 'Votre colis est en route.',
      icon: Icons.local_shipping_outlined,
    ),
    OrderStep(
      label: 'Livrée',
      description: 'Votre colis a été livré.',
      icon: Icons.home_outlined,
    ),
  ];

  /// Index de l'étape atteinte (0-4) pour un statut donné. Une commande
  /// annulée ou remboursée renvoie -1.
  static int stepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'paid':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      default:
        return -1;
    }
  }

  static bool isCancelled(String status) =>
      const {'cancelled', 'refunded'}.contains(status.toLowerCase());

  /// Une commande peut être annulée tant qu'elle n'est pas expédiée/livrée.
  static bool canCancel(String status) =>
      const {'pending', 'paid', 'processing'}.contains(status.toLowerCase());

  /// Identifiant court et lisible.
  static String shortId(String id) {
    final cleaned = id.replaceAll('-', '');
    return cleaned.length > 8
        ? cleaned.substring(0, 8).toUpperCase()
        : cleaned.toUpperCase();
  }

  /// Met en forme une date ISO en français court (« 10 avr. 2026 »).
  static String formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
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
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  /// Trie les commandes de la plus récente à la plus ancienne.
  static List<Order> sortByDate(List<Order> orders) {
    final copy = [...orders];
    copy.sort((a, b) {
      final da = DateTime.tryParse(a.createdAt);
      final db = DateTime.tryParse(b.createdAt);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return copy;
  }
}
