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

  SubscriptionsController(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  Day get today => Day.fromLocal(clock());

  Future<void> initialize() async {
    try {
      ledger = await store.load();
      await reconcile();
      error = null;
    } catch (_) {
      error = 'Could not open local data. Retry to keep your data safe.';
    }
    loading = false;
    notifyListeners();
  }

  /// Serialized copy-mutate-save-swap of the ledger.
  Future<void> commit(void Function(Ledger draft) mutate) {
    final task = _writes.then((_) async {
      final draft = ledger.clone();
      mutate(draft);
      await store.save(draft);
      ledger = draft;
      notifyListeners();
    });
    _writes = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  Future<void> reconcile() =>
      commit((draft) => Timeline.reconcile(draft, today, clock()));

  List<Subscription> get active =>
      ledger.subscriptions.values.where((s) => s.terms.active).toList();

  List<Payment> payments(Day from, Day until) =>
      Timeline.query(ledger, from, until, today, clock());

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
    // Independent historical payment snapshots remain queryable.
  });
}
