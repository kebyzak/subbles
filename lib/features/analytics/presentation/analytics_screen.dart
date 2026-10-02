import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/format/money_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/empty_state.dart';
import 'package:subbles/core/widgets/panel.dart';
import 'package:subbles/core/widgets/section_title.dart';
import 'package:subbles/core/widgets/service_icon.dart';
import 'package:subbles/features/analytics/domain/spending.dart';
import 'package:subbles/features/analytics/presentation/widgets/spending_chart.dart';
import 'package:subbles/features/fx/presentation/widgets/currency_selector.dart';
import 'package:subbles/features/fx/presentation/widgets/fx_note.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';

class AnalyticsScreen extends StatefulWidget {
  final SubscriptionsController subs;
  final FxController fx;

  const AnalyticsScreen(this.subs, this.fx, {super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Day period;
  bool yearly = false, percentage = false;

  @override
  void initState() {
    super.initState();
    period = widget.subs.today.monthStart;
    refresh();
  }

  Day get from => yearly ? Day(period.year, 1, 1) : period;

  Day get until => yearly ? Day(period.year + 1, 1, 1) : period.nextMonth;

  void refresh() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      widget.fx.refreshFx(widget.subs.payments(from, until));
    }
  });

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
    final payments = c.payments(from, until);
    final s = Spending.calculate(
      payments,
      c.ledger,
      c.ledger.displayCurrency,
      yearly: yearly,
    );
    final rankings = s.subscriptions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categories = s.categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final currency = c.ledger.displayCurrency;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Spending insights',
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
        const Text(
          'Know where the little things add up.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Month')),
            ButtonSegment(value: true, label: Text('Year')),
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
              tooltip: 'Previous period',
              onPressed: period.year > 2000 ? () => move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                yearly ? '${period.year}' : monthName(period),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next period',
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
            child: const Text('Current period'),
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          color: ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.missing > 0
                    ? 'ESTIMATED TOTAL · INCOMPLETE'
                    : yearly
                    ? 'ESTIMATED FULL-YEAR TOTAL'
                    : 'ESTIMATED MONTH TOTAL',
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
                      'SPENT SO FAR',
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
                      'ESTIMATED REMAINING',
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
        const SectionTitle('Spending over time'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  legend(accent, 'Historical'),
                  const SizedBox(width: 18),
                  legend(const Color(0xFFB7C8B5), 'Estimated'),
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
                  'Nothing to chart yet',
                  'Your spending timeline will appear here.',
                  icon: Icons.bar_chart_rounded,
                )
              else
                SizedBox(
                  height: 182,
                  child: SpendingChart(s, from, until, yearly),
                ),
              const SizedBox(height: 10),
              const Text(
                'Future spending uses the latest cached FX rate.',
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ),
        const SectionTitle('Top spending'),
        Panel(
          padding: const EdgeInsets.all(16),
          child: rankings.isEmpty
              ? const EmptyState(
                  'No converted spending',
                  'Add subscriptions or retrieve missing exchange rates.',
                )
              : Column(
                  children: rankings
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              ServiceIcon(s.icons[entry.key]!),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.names[entry.key]!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: rankings.first.value == 0
                                            ? 0
                                            : entry.value /
                                                  rankings.first.value,
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        SectionTitle(
          'By category',
          trailing: TextButton(
            onPressed: () => setState(() {
              percentage = !percentage;
            }),
            child: Text(percentage ? 'Show amount' : 'Show %'),
          ),
        ),
        Panel(
          child: categories.isEmpty
              ? const EmptyState(
                  'No category spending',
                  'Your categories will appear as payments are added.',
                )
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
                                categories[i].key,
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
            child: Text(
              'Missing conversions are excluded, never replaced with today’s historical FX. Browse Calendar to see every original amount.',
              style: TextStyle(color: muted, fontSize: 11, height: 1.5),
            ),
          ),
      ],
    );
  }

  Widget metric(String label, double value, String currency, int missing) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
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
            const Text(
              'Incomplete',
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
      Text(label, style: const TextStyle(fontSize: 10, color: muted)),
    ],
  );
}
