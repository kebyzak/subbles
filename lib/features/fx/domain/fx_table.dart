import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/core/domain/day.dart';

class FxTable {
  final Day date;
  final DateTime retrievedAt;

  final Map<String, double> rates;

  const FxTable(this.date, this.retrievedAt, this.rates);

  double? convert(int minor, String from, String to) {
    final original = Currency.get(from).major(minor);
    if (from == to) return original;
    final a = rates[from], b = rates[to];
    return a == null || b == null || a <= 0 || b <= 0 ? null : original * b / a;
  }

  Map<String, dynamic> toJson() => {
    'date': '$date',
    'retrievedAt': retrievedAt.toIso8601String(),
    'rates': rates,
  };

  factory FxTable.fromJson(Map<String, dynamic> j) => FxTable(
    Day.parse(j['date']),
    DateTime.parse(j['retrievedAt']),
    (j['rates'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
  );
}