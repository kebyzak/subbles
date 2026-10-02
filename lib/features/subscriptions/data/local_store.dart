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

  Future<void> save(Ledger ledger, {required Ledger previous});
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

  void syncRows<T>(
    Batch batch,
    String table,
    Map<String, T> previous,
    Map<String, T> current,
    Map<String, Object?> Function(String id, T value) encode,
  ) {
    for (final id in previous.keys) {
      if (!current.containsKey(id)) {
        batch.delete(table, where: 'id = ?', whereArgs: [id]);
      }
    }

    for (final entry in current.entries) {
      if (identical(previous[entry.key], entry.value)) continue;

      batch.insert(
        table,
        encode(entry.key, entry.value),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
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
  Future<void> save(Ledger ledger, {required Ledger previous}) =>
      db.transaction((txn) async {
        final batch = txn.batch();

        syncRows(
          batch,
          'subscriptions',
          previous.subscriptions,
          ledger.subscriptions,
          (id, s) => {'id': id, 'data': jsonEncode(s.toJson())},
        );

        syncRows(
          batch,
          'revisions',
          {for (final r in previous.revisions) r.id: r},
          {for (final r in ledger.revisions) r.id: r},
          (id, r) => {
            'id': id,
            'subscription_id': r.subscriptionId,
            'effective_date': '${r.effective}',
            'data': jsonEncode(r.toJson()),
          },
        );

        syncRows(
          batch,
          'payments',
          previous.history,
          ledger.history,
          (id, p) => {
            'id': id,
            'subscription_id': p.subscriptionId,
            'payment_date': '${p.date}',
            'data': jsonEncode(p.toJson()),
          },
        );

        syncRows<FxTable>(
          batch,
          'fx_cache',
          {
            ...previous.historicalFx,
            if (previous.latestFx != null) 'latest': previous.latestFx!,
          },
          {
            ...ledger.historicalFx,
            if (ledger.latestFx != null) 'latest': ledger.latestFx!,
          },
          (id, fx) => {'id': id, 'data': jsonEncode(fx.toJson())},
        );

        if (previous.displayCurrency != ledger.displayCurrency) {
          batch.insert('preferences', {
            'id': 'currency',
            'value': ledger.displayCurrency,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (previous.reconciledThrough != ledger.reconciledThrough) {
          if (ledger.reconciledThrough == null) {
            batch.delete(
              'preferences',
              where: 'id = ?',
              whereArgs: ['reconciledThrough'],
            );
          } else {
            batch.insert('preferences', {
              'id': 'reconciledThrough',
              'value': '${ledger.reconciledThrough}',
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final oldCategories = previous.categories.toSet();
        final newCategories = ledger.categories.toSet();

        for (final name in oldCategories.difference(newCategories)) {
          batch.delete('categories', where: 'name = ?', whereArgs: [name]);
        }

        for (final name in newCategories.difference(oldCategories)) {
          batch.insert('categories', {'name': name});
        }

        await batch.commit(noResult: true);
      });
}
