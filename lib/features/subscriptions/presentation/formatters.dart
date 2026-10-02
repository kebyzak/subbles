import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/core/format/money_format.dart';
import 'package:subbles/features/subscriptions/domain/terms.dart';

String original(Terms terms) => money(
  Currency.get(terms.currency).major(terms.amountMinor),
  terms.currency,
);
