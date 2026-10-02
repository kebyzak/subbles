import 'package:intl/intl.dart';

String money(double amount, String currency) =>
    '${NumberFormat('#,##0.##').format(amount)} $currency';
