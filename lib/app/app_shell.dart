import 'dart:async';

import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:flutter/services.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/show_error.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';
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
  final _pages = <Widget?>[null, null, null];
  final _pageUpdates = List.generate(3, (_) => ValueNotifier<int>(0));
  bool _checkingDay = false;

  void onSubscriptionsChanged() => _pageUpdates[tab].value++;

  Widget pageAt(int index) => _pages[index] ??= ListenableBuilder(
    listenable: _pageUpdates[index],
    builder: (context, _) {
      final page = switch (index) {
        0 => HomeScreen(widget.subs),
        1 => CalendarScreen(widget.subs, widget.fx, active: tab == index),
        _ => AnalyticsScreen(widget.subs, widget.fx, active: tab == index),
      };

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: index == 0 ? double.infinity : 760,
          ),
          child: page,
        ),
      );
    },
  );

  void selectTab(int value) {
    if (value == tab) return;

    final previous = tab;
    setState(() => tab = value);

    _pageUpdates[previous].value++;
    _pageUpdates[value].value++;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    lastDay = widget.subs.today;
    rollover = Timer.periodic(const Duration(seconds: 30), (_) => checkDay());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.subs.error == null) widget.fx.refreshFx([]);
    });
    widget.subs.addListener(onSubscriptionsChanged);
  }

  Future<void> checkDay() async {
    if (_checkingDay || widget.subs.today == lastDay) return;

    _checkingDay = true;

    try {
      final day = widget.subs.today;
      await widget.subs.reconcile();
      lastDay = day;
    } catch (_) {
      if (mounted) {
        showError(context, 'history_record_failed');
      }
    } finally {
      _checkingDay = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkDay();
      _pageUpdates[tab].value++;
    }
  }

  @override
  void dispose() {
    rollover?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.subs.removeListener(onSubscriptionsChanged);
    for (final notifier in _pageUpdates) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.subs,
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
                  AppText(c.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: c.initialize,
                    child: const AppText('storage_retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: bubbleCanvas,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              const Positioned.fill(child: BubbleBackdrop()),
              SafeArea(
                child: IndexedStack(
                  index: tab,
                  children: [
                    for (var i = 0; i < 3; i++)
                      TickerMode(
                        enabled: i == tab,
                        child: _pages[i] != null || i == tab
                            ? pageAt(i)
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: tab == 0
              ? Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF344D42), ink],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .25),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4420362F),
                        blurRadius: 26,
                        spreadRadius: -4,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    tooltip: context.tr('add_subscription'),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    highlightElevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => openEditor(context, c),
                    child: const Icon(Icons.add_rounded, size: 26),
                  ),
                )
              : null,
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DecoratedBox(
              decoration: bubbleSurfaceDecoration(radius: 100),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: NavigationBar(
                  height: 64,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: tab,
                  onDestinationSelected: selectTab,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.bubble_chart_outlined, size: 26),
                      selectedIcon: const Icon(Icons.bubble_chart, size: 26),
                      label: context.tr('home'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.calendar_month_outlined, size: 26),
                      selectedIcon: const Icon(Icons.calendar_month, size: 26),
                      label: context.tr('calendar'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.bar_chart_outlined, size: 26),
                      selectedIcon: const Icon(Icons.bar_chart, size: 26),
                      label: context.tr('analytics'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
