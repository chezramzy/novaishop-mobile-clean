import 'package:flutter/foundation.dart';

import '../../data/models/listing.dart';
import '../../data/models/product_variant.dart';

class CartItem {
  const CartItem({
    required this.listing,
    required this.quantity,
    this.variant,
    this.selectedOptions = const {},
  });

  final Listing listing;
  final int quantity;
  final ProductVariant? variant;
  final Map<String, String> selectedOptions;

  String get key {
    final optionKey = selectedOptions.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join('|');
    return '${listing.id}:${variant?.id ?? optionKey}';
  }

  double get unitPrice => variant?.price ?? listing.price;
  double get total => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      listing: listing,
      quantity: quantity ?? this.quantity,
      variant: variant,
      selectedOptions: selectedOptions,
    );
  }
}

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList(growable: false);
  int get count => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0, (sum, item) => sum + item.total);
  double get tax => subtotal * .1;
  double get discount => subtotal >= 100 ? subtotal * .2 : 0;
  double get total => subtotal + tax - discount;

  void add(
    Listing listing, {
    ProductVariant? variant,
    Map<String, String> selectedOptions = const {},
  }) {
    final item = CartItem(
      listing: listing,
      quantity: 1,
      variant: variant,
      selectedOptions: selectedOptions,
    );
    final current = _items[item.key];
    _items[item.key] = current == null
        ? item
        : current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
  }

  void decrease(String itemKey) {
    final current = _items[itemKey];
    if (current == null) return;
    if (current.quantity <= 1) {
      _items.remove(itemKey);
    } else {
      _items[itemKey] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  void remove(String itemKey) {
    _items.remove(itemKey);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
