import 'package:http/http.dart' as http;
import 'package:subbles/core/domain/day.dart';
import 'dart:io';

import 'package:subbles/features/fx/data/fx_service.dart';

Future<void> main() async {
  final client = http.Client();
  try {
    final provider = CurrencyApiProvider(client: client);
    final tables = await Future.wait([
      provider.fetch(),
      provider.fetch(date: const Day(2024, 3, 6)),
    ]);
    for (final table in tables) {
      stdout.writeln('${table.date}: ${table.rates}');
    }
  } finally {
    client.close();
  }
}
