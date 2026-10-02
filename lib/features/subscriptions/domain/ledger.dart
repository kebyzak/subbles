import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/fx/domain/fx_table.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';
import 'package:subbles/features/subscriptions/domain/revision.dart';
import 'package:subbles/features/subscriptions/domain/subscription.dart';

const defaultCategories = [
  'Entertainment',
  'Cloud storage',
  'Productivity',
  'Utilities',
  'Education',
  'AI',
  'Other',
];

class Ledger {
  final Map<String, Subscription> subscriptions;
  final List<Revision> revisions;
  final Map<String, Payment> history;
  final Map<String, FxTable> historicalFx;
  final List<String> categories;
  FxTable? latestFx;
  Day? reconciledThrough;
  String displayCurrency;

  Ledger({
    Map<String, Subscription>? subscriptions,
    List<Revision>? revisions,
    Map<String, Payment>? history,
    Map<String, FxTable>? historicalFx,
    List<String>? categories,
    this.latestFx,
    this.reconciledThrough,
    this.displayCurrency = 'KZT',
  }) : subscriptions = subscriptions ?? {},
       revisions = revisions ?? [],
       history = history ?? {},
       historicalFx = historicalFx ?? {},
       categories = categories ?? [...defaultCategories];

  double? convert(Payment p, String currency) {
    if (p.currency == currency) {
      return Currency.get(currency).major(p.amountMinor);
    }
    final fx = p.historical ? historicalFx['${p.date}'] : latestFx;
    return fx?.convert(p.amountMinor, p.currency, currency);
  }

  Ledger clone() => Ledger(
    subscriptions: {...subscriptions},
    revisions: [...revisions],
    history: {...history},
    historicalFx: {...historicalFx},
    categories: [...categories],
    latestFx: latestFx,
    reconciledThrough: reconciledThrough,
    displayCurrency: displayCurrency,
  );
}
