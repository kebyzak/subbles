import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/fx/domain/fx_table.dart';

abstract interface class FxProvider {
  Future<FxTable> fetch({Day? date});
}

class CurrencyApiProvider implements FxProvider {
  final http.Client client;
  final DateTime Function() clock;

  CurrencyApiProvider({http.Client? client, DateTime Function()? clock})
    : client = client ?? http.Client(),
      clock = clock ?? DateTime.now;

  @override
  Future<FxTable> fetch({Day? date}) async {
    final version = date?.toString() ?? 'latest';
    final urls = [
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$version/v1/currencies/usd.min.json',
      'https://$version.currency-api.pages.dev/v1/currencies/usd.min.json',
    ];
    for (final url in urls) {
      try {
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final actualDate = Day.parse(data['date'] as String);
        if (date != null && date != actualDate) continue;
        final raw = data['usd'] as Map<String, dynamic>;
        final rates = <String, double>{'USD': 1};
        for (final currency in Currency.supported) {
          final value = raw[currency.code.toLowerCase()];
          if (value is num && value > 0 && value.isFinite) {
            rates[currency.code] = value.toDouble();
          }
        }
        if (rates.length != Currency.supported.length) continue;
        return FxTable(actualDate, clock(), rates);
      } catch (_) {}
    }
    throw const FxUnavailable();
  }
}

class FxRepository {
  final FxProvider provider;
  final DateTime Function() clock;
  final Map<String, Future<FxTable?>> _inflight = {};
  final Map<String, DateTime> _failed = {};

  FxRepository(this.provider, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  Future<FxTable?> request({Day? date}) {
    final key = date?.toString() ?? 'latest';
    if (_inflight.containsKey(key)) return _inflight[key]!;
    final failed = _failed[key];
    if (failed != null &&
        clock().difference(failed) < const Duration(minutes: 15)) {
      return Future.value(null);
    }
    final future = _fetch(date, key);
    _inflight[key] = future;
    return future;
  }

  Future<FxTable?> _fetch(Day? date, String key) async {
    try {
      final result = await provider.fetch(date: date);
      if (date != null && result.date != date) throw const FxUnavailable();
      _failed.remove(key);
      return result;
    } catch (_) {
      _failed[key] = clock();
      return null;
    } finally {
      _inflight.remove(key);
    }
  }

  bool stale(FxTable? cached) =>
      cached == null ||
      clock().difference(cached.retrievedAt) >= const Duration(hours: 24);

  Future<Map<String, FxTable>> historical(Iterable<Day> dates) async {
    final queue = dates.toSet().toList();
    final result = <String, FxTable>{};
    var index = 0;
    var consecutiveFailures = 0;
    Future<void> worker() async {
      while (index < queue.length && consecutiveFailures < 3) {
        final date = queue[index++];
        final table = await request(date: date);
        if (table != null) {
          result['$date'] = table;
          consecutiveFailures = 0;
        } else {
          consecutiveFailures++;
        }
      }
    }

    await Future.wait(List.generate(3, (_) => worker()));
    return result;
  }
}

class FxUnavailable implements Exception {
  const FxUnavailable();
}
