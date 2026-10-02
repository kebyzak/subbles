import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';
import 'package:subbles/features/subscriptions/data/local_store.dart';
import 'package:subbles/features/subscriptions/domain/ledger.dart';
import 'package:subbles/features/subscriptions/domain/revision.dart';
import 'package:subbles/features/subscriptions/domain/subscription.dart';
import 'package:subbles/features/subscriptions/domain/terms.dart';
import 'package:subbles/features/subscriptions/domain/timeline.dart';
import 'package:uuid/uuid.dart';

class SubscriptionsController extends ChangeNotifier {
  final LocalStore store;
  final DateTime Function() clock;
  Ledger ledger = Ledger();
  bool loading = true;
  String? error;
  Future<void> _writes = Future.value();
  int dataVersion = 0;
  int _cachedVersion = -1;
  Day? _cachedDay;
  List<Subscription>? _activeCache;

  final _paymentCache = <(Day, Day), List<Payment>>{};

  void prepareCache(Day day) {
    if (_cachedVersion == dataVersion && _cachedDay == day) return;
    _cachedVersion = dataVersion;
    _cachedDay = day;
    _activeCache = null;
    _paymentCache.clear();
  }

  SubscriptionsController(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  Day get today => Day.fromLocal(clock());

  Future<void> initialize() async {
    try {
      ledger = await store.load();
      dataVersion++;
      await reconcile();
      error = null;
    } catch (_) {
      error = 'storage_open_failed';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> commit(void Function(Ledger draft) mutate) {
    final task = _writes.then((_) async {
      final previous = ledger;
      final draft = previous.clone();
      mutate(draft);
      await store.save(draft, previous: previous);
      ledger = draft;
      dataVersion++;
      notifyListeners();
    });
    _writes = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  Future<void> reconcile() =>
      commit((draft) => Timeline.reconcile(draft, today, clock()));

  List<Subscription> get active {
    prepareCache(today);

    return _activeCache ??= List<Subscription>.unmodifiable(
      ledger.subscriptions.values.where((s) => s.terms.active),
    );
  }

  List<Payment> payments(Day from, Day until) {
    final now = clock();
    final day = Day.fromLocal(now);
    prepareCache(day);

    final key = (from, until);
    final cached = _paymentCache.remove(key);

    if (cached != null) {
      _paymentCache[key] = cached;
      return cached;
    }

    final result = List<Payment>.unmodifiable(
      Timeline.query(ledger, from, until, day, now),
    );

    _paymentCache[key] = result;

    if (_paymentCache.length > 4) {
      _paymentCache.remove(_paymentCache.keys.first);
    }

    return result;
  }

  Future<void> saveSubscription(Terms terms, {String? id}) => commit((draft) {
    Timeline.reconcile(draft, today, clock());
    final subId = id ?? const Uuid().v4();
    final previous = draft.subscriptions[subId];
    final effective = previous == null && terms.anchor < today
        ? terms.anchor
        : today;
    draft.subscriptions[subId] = Subscription(
      subId,
      terms,
      previous?.createdAt ?? clock(),
      clock(),
    );
    draft.revisions.removeWhere(
      (r) => r.subscriptionId == subId && r.effective == effective,
    );
    draft.revisions.add(
      Revision(const Uuid().v4(), subId, effective, terms, clock()),
    );
    if (draft.reconciledThrough != null &&
        effective < draft.reconciledThrough!) {
      draft.reconciledThrough = effective;
    }
    Timeline.reconcile(draft, today, clock());
  });

  Future<void> deactivate(String id) {
    final s = ledger.subscriptions[id]!;
    return saveSubscription(s.terms.withActive(false), id: id);
  }

  Future<void> delete(String id) => commit((draft) {
    Timeline.reconcile(draft, today, clock());
    draft.subscriptions.remove(id);
    draft.revisions.removeWhere((r) => r.subscriptionId == id);
  });
}
