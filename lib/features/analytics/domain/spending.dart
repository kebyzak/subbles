import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';
import 'package:subbles/features/subscriptions/domain/ledger.dart';

class Spending {
  double spent = 0, remaining = 0;
  int missingHistorical = 0, missingProjected = 0;
  final Map<String, double> subscriptions = {}, categories = {};
  final Map<String, String> names = {}, icons = {};
  final Map<Day, double> actualGraph = {}, projectedGraph = {};

  int get missing => missingHistorical + missingProjected;

  double get total => spent + remaining;

  factory Spending.calculate(
    List<Payment> payments,
    Ledger ledger,
    String currency, {
    bool yearly = false,
  }) {
    final result = Spending._();
    for (final p in payments) {
      final value = ledger.convert(p, currency);
      if (value == null) {
        if (p.historical) {
          result.missingHistorical++;
        } else {
          result.missingProjected++;
        }
        continue;
      }
      if (p.historical) {
        result.spent += value;
      } else {
        result.remaining += value;
      }
      result.names[p.subscriptionId] = p.snapshot.name;
      result.icons[p.subscriptionId] = p.snapshot.icon;
      result.subscriptions.update(
        p.subscriptionId,
        (v) => v + value,
        ifAbsent: () => value,
      );
      result.categories.update(
        p.snapshot.category,
        (v) => v + value,
        ifAbsent: () => value,
      );
      final graph = p.historical ? result.actualGraph : result.projectedGraph;
      final bucket = yearly ? p.date.monthStart : p.date;
      graph.update(bucket, (v) => v + value, ifAbsent: () => value);
    }
    return result;
  }

  Spending._();
}
