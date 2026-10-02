import 'package:flutter/material.dart';
import 'package:subbles/app/app.dart';
import 'package:subbles/core/theme/app_theme.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/fx/data/fx_service.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/subscriptions/data/local_store.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final subs = SubscriptionsController(await SqliteStore.open());
    await subs.initialize();
    final fx = FxController(subs, FxRepository(CurrencyApiProvider()));
    runApp(MainApp(subs: subs, fx: fx));
  } catch (_) {
    runApp(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Local storage could not be opened. Restart the app to retry. Your stored data has not been reset.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
