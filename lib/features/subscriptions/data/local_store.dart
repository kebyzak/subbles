import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/fx/domain/fx_table.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';
import 'package:subbles/features/subscriptions/domain/ledger.dart';
import 'package:subbles/features/subscriptions/domain/revision.dart';
import 'package:subbles/features/subscriptions/domain/subscription.dart';

abstract interface class LocalStore {
  Future<Ledger> load();

  Future<void> save(Ledger ledger);
}

class SqliteStore implements LocalStore {
  final Database db;

  SqliteStore(this.db);

  static Future<SqliteStore> open() async => SqliteStore(
    await openDatabase(
      path.join(await getDatabasesPath(), 'subbles.db'),
      version: 1,
      onCreate: createSchema,
    ),
  );

  static Future<void> createSchema(Database db, int version) async {
    await db.execute(
      'CREATE TABLE subscriptions (id TEXT PRIMARY KEY, data TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE revisions (id TEXT PRIMARY KEY, subscription_id TEXT NOT NULL, effective_date TEXT NOT NULL, data TEXT NOT NULL, UNIQUE(subscription_id, effective_date))',
    );
    await db.execute(
      'CREATE INDEX revision_timeline ON revisions(subscription_id, effective_date)',
    );
    await db.execute(
      'CREATE TABLE payments (id TEXT PRIMARY KEY, subscription_id TEXT NOT NULL, payment_date TEXT NOT NULL, data TEXT NOT NULL, UNIQUE(subscription_id, payment_date))',
    );
    await db.execute('CREATE INDEX payment_timeline ON payments(payment_date)');
    await db.execute(
      'CREATE TABLE fx_cache (id TEXT PRIMARY KEY, data TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE preferences (id TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.execute('CREATE TABLE categories (name TEXT PRIMARY KEY)');
  }

  @override
  Future<Ledger> load() async {
    final result = Ledger();
    Map<String, dynamic> decode(Map<String, Object?> row) =>
        jsonDecode(row['data'] as String) as Map<String, dynamic>;
    for (final row in await db.query('subscriptions')) {
      final s = Subscription.fromJson(decode(row));
      result.subscriptions[s.id] = s;
    }
    for (final row in await db.query('revisions')) {
      result.revisions.add(Revision.fromJson(decode(row)));
    }
    for (final row in await db.query('payments')) {
      final p = Payment.fromJson(decode(row));
      result.history[p.id] = p;
    }
    for (final row in await db.query('fx_cache')) {
      final fx = FxTable.fromJson(decode(row));
      if (row['id'] == 'latest') {
        result.latestFx = fx;
      } else {
        result.historicalFx[row['id'] as String] = fx;
      }
    }
    for (final row in await db.query('preferences')) {
      if (row['id'] == 'currency') {
        result.displayCurrency = row['value'] as String;
      }
      if (row['id'] == 'reconciledThrough') {
        result.reconciledThrough = Day.parse(row['value'] as String);
      }
    }
    final categories = await db.query('categories');
    if (categories.isNotEmpty) {
      result.categories
        ..clear()
        ..addAll(categories.map((row) => row['name'] as String));
    }
    return result;
  }

  @override
  Future<void> save(Ledger ledger) => db.transaction((txn) async {
    final batch = txn.batch();
    for (final table in [
      'subscriptions',
      'revisions',
      'payments',
      'fx_cache',
      'preferences',
      'categories',
    ]) {
      batch.delete(table);
    }
    for (final s in ledger.subscriptions.values) {
      batch.insert('subscriptions', {
        'id': s.id,
        'data': jsonEncode(s.toJson()),
      });
    }
    for (final r in ledger.revisions) {
      batch.insert('revisions', {
        'id': r.id,
        'subscription_id': r.subscriptionId,
        'effective_date': '${r.effective}',
        'data': jsonEncode(r.toJson()),
      });
    }
    for (final p in ledger.history.values) {
      batch.insert('payments', {
        'id': p.id,
        'subscription_id': p.subscriptionId,
        'payment_date': '${p.date}',
        'data': jsonEncode(p.toJson()),
      });
    }
    if (ledger.latestFx != null) {
      batch.insert('fx_cache', {
        'id': 'latest',
        'data': jsonEncode(ledger.latestFx!.toJson()),
      });
    }
    for (final entry in ledger.historicalFx.entries) {
      batch.insert('fx_cache', {
        'id': entry.key,
        'data': jsonEncode(entry.value.toJson()),
      });
    }
    batch.insert('preferences', {
      'id': 'currency',
      'value': ledger.displayCurrency,
    });
    if (ledger.reconciledThrough != null) {
      batch.insert('preferences', {
        'id': 'reconciledThrough',
        'value': '${ledger.reconciledThrough}',
      });
    }
    for (final category in ledger.categories) {
      batch.insert('categories', {'name': category});
    }
    await batch.commit(noResult: true);
  });
}
