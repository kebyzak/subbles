import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';
import 'package:subbles/features/subscriptions/domain/ledger.dart';
import 'package:subbles/features/subscriptions/domain/revision.dart';

class Timeline {
  static void reconcile(Ledger ledger, Day today, DateTime now) {
    final grouped = <String, List<Revision>>{};
    for (final r in ledger.revisions) {
      grouped.putIfAbsent(r.subscriptionId, () => []).add(r);
    }
    for (final revisions in grouped.values) {
      revisions.sort((a, b) => a.effective.compareTo(b.effective));
      for (var i = 0; i < revisions.length; i++) {
        final r = revisions[i];
        if (!r.terms.active || !(r.effective < today)) continue;
        final until =
            i + 1 < revisions.length && revisions[i + 1].effective < today
            ? revisions[i + 1].effective
            : today;
        var from = r.effective;
        final watermark = ledger.reconciledThrough;
        if (watermark != null && from < watermark) from = watermark;
        for (final d in r.terms.recurrence.between(
          r.terms.anchor,
          from,
          until,
        )) {
          final id = '${r.subscriptionId}:$d';
          ledger.history.putIfAbsent(
            id,
            () => Payment(
              id,
              r.subscriptionId,
              d,
              r.terms,
              PaymentType.historical,
              now,
            ),
          );
        }
      }
    }
    if (ledger.reconciledThrough == null || ledger.reconciledThrough! < today) {
      ledger.reconciledThrough = today;
    }
  }

  static List<Payment> query(
    Ledger ledger,
    Day from,
    Day until,
    Day today,
    DateTime now,
  ) {
    final payments = ledger.history.values
        .where((p) => from <= p.date && p.date < until)
        .toList();
    final projectedFrom = from < today ? today : from;
    for (final s in ledger.subscriptions.values) {
      if (!s.terms.active) continue;
      for (final d in s.terms.recurrence.between(
        s.terms.anchor,
        projectedFrom,
        until,
      )) {
        if (ledger.history.containsKey('${s.id}:$d')) continue;
        payments.add(
          Payment('${s.id}:$d', s.id, d, s.terms, PaymentType.projected, now),
        );
      }
    }
    payments.sort((a, b) {
      final dates = a.date.compareTo(b.date);
      return dates != 0 ? dates : a.snapshot.name.compareTo(b.snapshot.name);
    });
    return payments;
  }
}
