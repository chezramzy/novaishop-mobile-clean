import 'package:intl/intl.dart';

/// Prix affichés en franc CFA BCEAO (XOF), sans décimales.
final _currencyFormat = NumberFormat.currency(
  locale: 'fr_SN',
  name: 'XOF',
  symbol: 'FCFA',
  decimalDigits: 0,
);

String formatPrice(num value) => _currencyFormat.format(value);
