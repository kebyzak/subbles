# Subbles

A personal, local-first Flutter subscription tracker. Home, Calendar, and
Analytics are the only navigation destinations. No account, backend, bank
integration, payment processing, or sync. Network requests retrieve FX only.

## Run

Requires Flutter 3.41 / Dart 3.11 or newer and an Android or iOS toolchain.

```sh
flutter pub get
flutter run
flutter test
flutter analyze
flutter build apk --debug
```

Optional live FX smoke check: `dart run tool/verify_fx.dart` (one current and
one historical public rate table; no local database changes).

SQLite persistence supports Android, iOS, and macOS through `sqflite`. The
starter web, Windows, and Linux targets are not supported by this mobile V1.
iOS builds require macOS. No API keys are required.

## Local database and source of truth

The version-1 `subbles.db` database contains independent, indexed records:

| Table | Key / index | Contents |
| --- | --- | --- |
| subscriptions | id | Current immutable terms, creation and update timestamps |
| revisions | id; unique subscription + effective date | Complete terms and original recurrence anchor, effective date, creation timestamp |
| payments | id; unique subscription + date; date index | Independent historical name/icon/category/frequency/amount/currency snapshots |
| fx_cache | latest or ISO date | All supported currencies per USD, provider rate date and retrieval timestamp |
| preferences | id | Display currency and reconciliation watermark |
| categories | name | Persisted initial categories |

Payloads are JSON within SQLite rows; searchable identities/dates have SQL
columns and indexes. Schema upgrades belong in the store's SQLite version
migrations. The small single-user ledger is committed as one SQLite transaction,
including catch-up history and its watermark. Writes are serialized, and failed
transactions do not publish changed in-memory state. No foreign key cascades
can destroy a deleted subscription's history.

Amounts are integer minor units with ISO currency codes. Conversion never changes
these amounts. `Currency.supported` defines currencies and decimal precision;
the same registry drives selectors and FX validation.

## Billing rules

- Billing uses `Day` (YYYY-MM-DD); timestamps only describe creation/retrieval.
  UTC containers perform calendar arithmetic without converting billing dates
  to instants or applying time-zone offsets.
- Each recurrence advances from its original anchor. Monthly 31st billing
  clamps to February's final day and returns to March 31. Yearly February 29
  returns to February 29 in leap years. Custom intervals use days, weeks, months,
  or years (1–120). Queries seek directly into the requested range.
- Dates **before today** are historical. Today and later are projected. A charge
  scheduled today becomes historical tomorrow. Historical entries are assumed
  scheduled charges; the app does not verify whether a merchant actually charged.
- On startup, resume/date rollover, and before any edit/cancellation/deletion,
  reconciliation materializes elapsed dates using each revision's half-open
  effective window. Unique subscription/date IDs and insert-if-absent snapshots
  make reconciliation idempotent, even after months offline.
- Edits apply today. The final edit on a given calendar date governs that date.
  Earlier snapshots are immutable. Merely editing a price retains the original
  billing anchor, including the 31st after February. Explicitly changing date or
  frequency creates a new anchor. V1 does not schedule future-dated term changes
  or retroactively edit past financial terms.
- A new subscription with a past anchor assumes its entered terms applied from
  that date; the form explains the resulting historical entries. The app cannot
  infer prices that changed before the subscription was entered.
- Deactivation stops projections from today and keeps history. Reactivation
  leaves inactive periods empty. Deletion reconciles first, removes current terms
  and revisions, and always retains independent historical payments.
- Future payments are computed only for the queried period and never stored.

## FX and analytics

`FxProvider` is replaceable. `CurrencyApiProvider` uses the free, keyless
[Currency API](https://github.com/fawazahmed0/exchange-api), with jsDelivr as
primary and its Cloudflare endpoint as fallback. Each request gets a whole USD
base table, enabling KZT/USD/EUR cross-conversion with one table per date.

Latest FX is fresh for 24 hours after retrieval. Historical FX is cached
indefinitely and must match the requested date exactly. Requests are deduplicated
by date with at most three concurrent historical downloads. Failed dates have
a 15-minute retry cooldown; repeated failures stop the batch to avoid excessive
offline requests. Unavailable old dates remain unavailable. Period changes during
a fetch queue their required dates instead of losing the refresh.

Historical spending uses the payment-date cache; future spending uses latest
available rates and is labeled estimated. Same-currency values need no FX.
Missing cross-currency rates are excluded from converted totals, charts, rankings,
and category shares with an explicit incomplete-data message. Original amounts
are always available in Calendar. Today's rate is never silently substituted for
a missing historical rate. FX status includes retrieval time, rate date, and
cached/stale state. Selecting a display currency persists across restarts and
recalculates Calendar, Analytics, and Home bubble sizes.

Calendar merges historical rows with current-term projections for the selected
month. Analytics does the same for a month/year, separating historical spending
and estimated remaining spending, and grouping chart data by day/month. Rankings
use converted period contributions; categories use snapshotted historical
categories and current projected categories.

## Code and verification

- `lib/domain/`: dates, recurrence, money, immutable models, reconciliation,
  range queries, conversion and aggregation; independent of widgets/storage.
- `lib/data/`: SQLite transaction store and FX provider/repository.
- `lib/app_controller.dart`: serialized mutations, reconciliation, persisted
  preference and queued FX updates.
- `lib/ui/`: three screens, add/edit/details sheets and bounded collision physics.
- `test/`: recurrence boundaries, dated term changes, cancellations/deletions,
  offline/restart behavior, mixed historical/projected periods, FX correctness,
  SQLite round-trip/rollback, phone layouts and form/bubble interactions.

Widget tests use disposable sample data only; the real app starts empty. They
write review images to `build/previews/`. On Windows the test renderer optionally
loads local fonts for readable images. No demo payments or fabricated FX rates
are inserted into a real device database.
