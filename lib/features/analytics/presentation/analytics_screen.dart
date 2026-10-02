import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/format/money_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/empty_state.dart';
import 'package:subbles/core/widgets/panel.dart';
import 'package:subbles/core/widgets/section_title.dart';
import 'package:subbles/core/widgets/service_icon.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';
import 'package:subbles/features/analytics/domain/spending.dart';
import 'package:subbles/features/analytics/presentation/widgets/spending_chart.dart';
import 'package:subbles/features/fx/presentation/widgets/currency_selector.dart';
import 'package:subbles/features/fx/presentation/widgets/fx_note.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';

class AnalyticsScreen extends StatefulWidget {
  final SubscriptionsController subs;
  final FxController fx;
  final bool active;

  const AnalyticsScreen(this.subs, this.fx, {super.key, this.active = true});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Day period;
  bool yearly = false, percentage = false;
  int _preparedVersion = -1;
  Day? _preparedToday;
  (Day, Day, bool)? _preparedPeriod;
  List<Payment> _payments = const [];
  Spending? _spending;
  bool _refreshScheduled = false;
  int _fxVersion = -1;
  Day? _fxDay;
  List<MapEntry<String, double>> _rankings = const [];
  List<MapEntry<String, double>> _categories = const [];

  void prepareAnalytics() {
    final c = widget.subs;
    final today = c.today;
    final key = (from, until, yearly);

    if (_preparedVersion == c.dataVersion &&
        _preparedToday == today &&
        _preparedPeriod == key) {
      return;
    }

    _payments = c.payments(from, until);
    final spending = Spending.calculate(
      _payments,
      c.ledger,
      c.ledger.displayCurrency,
      yearly: yearly,
    );

    _spending = spending;
    _rankings = spending.subscriptions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _categories = spending.categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _preparedVersion = c.dataVersion;
    _preparedToday = today;
    _preparedPeriod = key;
  }

  @override
  void initState() {
    super.initState();
    period = widget.subs.today.monthStart;
    refresh();
  }

  @override
  void didUpdateWidget(covariant AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active &&
        (!oldWidget.active ||
            _fxVersion != widget.subs.dataVersion ||
            _fxDay != widget.subs.today ||
            widget.fx.fx.stale(widget.subs.ledger.latestFx))) {
      refresh();
    }
  }

  Day get from => yearly ? Day(period.year, 1, 1) : period;
  Day get until => yearly ? Day(period.year + 1, 1, 1) : period.nextMonth;

  void refresh() {
    if (!widget.active || _refreshScheduled) return;
    _refreshScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted || !widget.active) return;

      _fxVersion = widget.subs.dataVersion;
      _fxDay = widget.subs.today;

      widget.fx.refreshFx(widget.subs.payments(from, until));
    });
  }

  void move(int delta) {
    setState(() {
      period = yearly
          ? Day(period.year + delta, period.month, 1)
          : Day.fromLocal(DateTime.utc(period.year, period.month + delta, 1));
    });
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.subs;
    prepareAnalytics();
    final payments = _payments;
    final s = _spending!;
    final rankings = _rankings;
    final categories = _categories;
    final currency = c.ledger.displayCurrency;

    final rankingIndexes = {
      for (var i = 0; i < rankings.length; i++) rankings[i].key: i,
    };
    final header = <Widget>[
      Row(
        children: [
          const Expanded(
            child: AppText(
              'spending_insights',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.1,
              ),
            ),
          ),
          CurrencySelector(widget.fx, onChanged: refresh),
        ],
      ),
      const SizedBox(height: 12),
      const AppText('analytics_hint', style: TextStyle(color: muted)),
      const SizedBox(height: 24),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: AppText('month')),
          ButtonSegment(value: true, label: AppText('year')),
        ],
        selected: {yearly},
        showSelectedIcon: false,
        onSelectionChanged: (values) {
          setState(() {
            yearly = values.first;
          });
          refresh();
        },
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          IconButton(
            tooltip: context.tr('previous_period'),
            onPressed: period.year > 2000 ? () => move(-1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              yearly ? '${period.year}' : monthName(period),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: context.tr('next_period'),
            onPressed: period.year < 2200 ? () => move(1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      Align(
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () {
            setState(() {
              period = c.today.monthStart;
            });
            refresh();
          },
          child: const AppText('current_period'),
        ),
      ),
      const SizedBox(height: 10),
      Panel(
        color: ink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              s.missing > 0
                  ? 'estimated_incomplete'
                  : yearly
                  ? 'estimated_year'
                  : 'estimated_month',
              style: const TextStyle(
                color: Color(0xFFBDD3C0),
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              child: Text(
                '~${money(s.total, currency)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 38,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: metric(
                    'spent_so_far',
                    s.spent,
                    currency,
                    s.missingHistorical,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: .15),
                ),
                Expanded(
                  child: metric(
                    'estimated_remaining',
                    s.remaining,
                    currency,
                    s.missingProjected,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      FxNote(widget.fx, missing: s.missing),
      const SectionTitle('spending_time'),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                legend(accent, 'historical'),
                const SizedBox(width: 18),
                legend(const Color(0xFFB7C8B5), 'estimated'),
                const Spacer(),
                Text(
                  currency,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (payments.isEmpty)
              const EmptyState(
                'nothing_chart',
                'chart_hint',
                icon: Icons.bar_chart_rounded,
              )
            else
              SizedBox(
                height: 182,
                child: SpendingChart(s, from, until, yearly),
              ),
            const SizedBox(height: 10),
            const AppText(
              'future_fx_note',
              style: TextStyle(fontSize: 10, color: muted),
            ),
          ],
        ),
      ),
      const SectionTitle('top_spending'),
    ];
    final footer = <Widget>[
      SectionTitle(
        'by_category',
        trailing: TextButton(
          onPressed: () => setState(() {
            percentage = !percentage;
          }),
          child: AppText(percentage ? 'show_amount' : 'show_percent'),
        ),
      ),
      Panel(
        child: categories.isEmpty
            ? const EmptyState('no_categories', 'categories_hint')
            : Column(
                children: [
                  SizedBox(
                    height: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          for (var i = 0; i < categories.length; i++)
                            Expanded(
                              flex: math.max(
                                1,
                                (categories[i].value /
                                        math.max(s.total, .01) *
                                        10000)
                                    .round(),
                              ),
                              child: ColoredBox(
                                color: bubbleColors[i % bubbleColors.length],
                                child: const SizedBox.expand(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < categories.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bubbleColors[i % bubbleColors.length],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              categoryText(context, categories[i].key),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            percentage
                                ? '${(categories[i].value / math.max(s.total, .01) * 100).toStringAsFixed(1)}%'
                                : '~${money(categories[i].value, currency)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
      if (s.missing > 0)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: AppText(
            'missing_conversions_note',
            style: TextStyle(color: muted, fontSize: 11, height: 1.5),
          ),
        ),
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          sliver: SliverList(delegate: SliverChildListDelegate(header)),
        ),
        if (rankings.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Panel(
                padding: EdgeInsets.all(16),
                child: EmptyState('no_converted', 'retrieve_rates_hint'),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: DecoratedSliver(
              decoration: bubbleSurfaceDecoration(),
              sliver: SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => KeyedSubtree(
                      key: ValueKey(rankings[index].key),
                      child: rankingRow(
                        rankings[index],
                        s,
                        currency,
                        rankings.first.value,
                      ),
                    ),
                    childCount: rankings.length,
                    findChildIndexCallback: (key) {
                      if (key is! ValueKey<String>) return null;
                      return rankingIndexes[key.value];
                    },
                  ),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          sliver: SliverList(delegate: SliverChildListDelegate(footer)),
        ),
      ],
    );
  }

  Widget rankingRow(
    MapEntry<String, double> entry,
    Spending spending,
    String currency,
    double maximum,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        ServiceIcon(spending.icons[entry.key]!),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spending.names[entry.key]!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: maximum == 0 ? 0 : entry.value / maximum,
                  minHeight: 4,
                  color: accent,
                  backgroundColor: paper,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '~${money(entry.value, currency)}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget metric(String label, double value, String currency, int missing) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: const TextStyle(
              color: Color(0xFFBDD3C0),
              fontSize: 9,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            child: Text(
              money(value, currency),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (missing > 0)
            const AppText(
              'incomplete',
              style: TextStyle(color: Color(0xFFEECFA1), fontSize: 11),
            ),
        ],
      );

  Widget legend(Color color, String label) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      AppText(label, style: const TextStyle(fontSize: 10, color: muted)),
    ],
  );
}
