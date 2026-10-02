import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:subbles/features/fx/data/fx_service.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';

class FxController extends ChangeNotifier {
  final SubscriptionsController subscriptions;
  final FxRepository fx;
  bool fetchingFx = false, cachedFx = false;
  String? error;
  Future<void>? _fxTask;
  final Map<String, Payment> _queuedPayments = {};

  FxController(this.subscriptions, this.fx);

  Future<void> selectCurrency(String currency) {
    if (subscriptions.ledger.displayCurrency == currency) {
      return Future<void>.value();
    }
    return subscriptions.commit((draft) => draft.displayCurrency = currency);
  }

  Future<void> refreshFx(List<Payment> payments) {
    final ledger = subscriptions.ledger;

    for (final p in payments) {
      final needsHistoricalFx =
          p.historical &&
          p.currency != ledger.displayCurrency &&
          !ledger.historicalFx.containsKey('${p.date}');

      if (needsHistoricalFx) _queuedPayments[p.id] = p;
    }

    final running = _fxTask;
    if (running != null) return running;

    if (!fx.stale(ledger.latestFx) && _queuedPayments.isEmpty) {
      return Future<void>.value();
    }

    return _fxTask = _refreshFx().whenComplete(() => _fxTask = null);
  }

  Future<void> _refreshFx() async {
    fetchingFx = true;
    notifyListeners();
    try {
      if (fx.stale(subscriptions.ledger.latestFx)) {
        final latest = await fx.request();
        cachedFx = latest == null;
        if (latest != null) {
          await subscriptions.commit((draft) => draft.latestFx = latest);
        }
      }
      do {
        final payments = _queuedPayments.values.toList();
        _queuedPayments.clear();
        final ledger = subscriptions.ledger;
        final dates = payments
            .where(
              (p) =>
                  p.historical &&
                  p.currency != ledger.displayCurrency &&
                  !ledger.historicalFx.containsKey('${p.date}'),
            )
            .map((p) => p.date);
        final tables = await fx.historical(dates);
        if (tables.isNotEmpty) {
          await subscriptions.commit(
            (draft) => draft.historicalFx.addAll(tables),
          );
        }
      } while (_queuedPayments.isNotEmpty);
    } catch (_) {
      error = 'fx_save_failed';
    } finally {
      fetchingFx = false;
      notifyListeners();
    }
  }
}
