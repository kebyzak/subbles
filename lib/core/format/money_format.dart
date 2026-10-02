import 'package:intl/intl.dart';

final _moneyFormats = <String, NumberFormat>{};

String money(double amount, String currency) {
  final locale = Intl.getCurrentLocale();
  final formatter = _moneyFormats.putIfAbsent(
    locale,
    () => NumberFormat('#,##0.##', locale),
  );

  return '${formatter.format(amount)} $currency';
}
