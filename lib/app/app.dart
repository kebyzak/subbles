import 'package:flutter/material.dart';
import 'package:subbles/app/app_shell.dart';
import 'package:subbles/core/theme/app_theme.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';

class MainApp extends StatelessWidget {
  final SubscriptionsController subs;
  final FxController fx;

  const MainApp({super.key, required this.subs, required this.fx});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Subbles',
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: AppShell(subs, fx),
  );
}
