import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:subbles/app/app.dart';
import 'package:subbles/core/theme/app_theme.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/fx/data/fx_service.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/subscriptions/data/local_store.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting();
  try {
    final subs = SubscriptionsController(await SqliteStore.open());
    await subs.initialize();
    final fx = FxController(subs, FxRepository(CurrencyApiProvider()));
    runApp(
      AppLocalization(
        child: MainApp(subs: subs, fx: fx),
      ),
    );
  } catch (_) {
    runApp(const AppLocalization(child: _StorageFailureApp()));
  }
}

class _StorageFailureApp extends StatelessWidget {
  const _StorageFailureApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: appTheme,
    localizationsDelegates: context.localizationDelegates,
    supportedLocales: context.supportedLocales,
    locale: context.locale,
    home: const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: AppText('storage_start_failed', textAlign: TextAlign.center),
          ),
        ),
      ),
    ),
  );
}
