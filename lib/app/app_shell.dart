import 'dart:async';

import 'package:flutter/material.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/show_error.dart';
import 'package:subbles/features/analytics/presentation/analytics_screen.dart';
import 'package:subbles/features/calendar/presentation/calendar_screen.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/home/presentation/home_screen.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_editor.dart';

class AppShell extends StatefulWidget {
  final SubscriptionsController subs;
  final FxController fx;

  const AppShell(this.subs, this.fx, {super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int tab = 0;
  Timer? rollover;
  late Day lastDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    lastDay = widget.subs.today;
    rollover = Timer.periodic(const Duration(seconds: 30), (_) => checkDay());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.subs.error == null) widget.fx.refreshFx([]);
    });
  }

  Future<void> checkDay() async {
    if (widget.subs.today == lastDay) return;
    try {
      await widget.subs.reconcile();
      lastDay = widget.subs.today;
    } catch (_) {
      if (mounted) {
        showError(context, 'Could not record scheduled history. Please retry.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkDay();
  }

  @override
  void dispose() {
    rollover?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.subs, widget.fx]),
    builder: (context, _) {
      final c = widget.subs;
      if (c.loading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (c.error != null && c.ledger.reconciledThrough == null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: c.initialize,
                    child: const Text('Retry local storage'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tab == 0 ? double.infinity : 760,
              ),
              child: switch (tab) {
                0 => HomeScreen(c, widget.fx),
                1 => CalendarScreen(c, widget.fx),
                _ => AnalyticsScreen(c, widget.fx),
              },
            ),
          ),
        ),
        floatingActionButton: tab == 0
            ? FloatingActionButton(
                tooltip: 'Add subscription',
                backgroundColor: ink,
                foregroundColor: Colors.white,
                onPressed: () => openEditor(context, c),
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() {
            tab = value;
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.bubble_chart_outlined),
              selectedIcon: Icon(Icons.bubble_chart),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
          ],
        ),
      );
    },
  );
}
