import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/format/money_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/empty_state.dart';
import 'package:subbles/core/widgets/panel.dart';
import 'package:subbles/core/widgets/section_title.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';
import 'package:subbles/core/widgets/service_icon.dart';
import 'package:subbles/features/analytics/domain/spending.dart';
import 'package:subbles/features/fx/presentation/widgets/currency_selector.dart';
import 'package:subbles/features/fx/presentation/widgets/fx_note.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';
import 'package:subbles/features/subscriptions/presentation/widgets/payment_row.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_details.dart';

class CalendarScreen extends StatefulWidget {
  final SubscriptionsController subs;
  final FxController fx;
  final bool active;

  const CalendarScreen(this.subs, this.fx, {super.key, this.active = true});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Day month;
  Day? selected;
  int _preparedVersion = -1;
  Day? _preparedMonth;
  Day? _preparedToday;
  List<Payment> _payments = const [];
  Map<Day, List<Payment>> _byDay = {};
  bool _refreshScheduled = false;
  int _fxVersion = -1;
  Day? _fxDay;
  Spending? _spending;

  void prepareMonth() {
    final c = widget.subs;
    final today = c.today;

    if (_preparedVersion == c.dataVersion &&
        _preparedMonth == month &&
        _preparedToday == today) {
      return;
    }

    _payments = c.payments(month, month.nextMonth);
    _byDay = {};

    for (final payment in _payments) {
      (_byDay[payment.date] ??= []).add(payment);
    }

    _spending = Spending.calculate(
      _payments,
      c.ledger,
      c.ledger.displayCurrency,
    );

    _preparedVersion = c.dataVersion;
    _preparedMonth = month;
    _preparedToday = today;
  }

  @override
  void initState() {
    super.initState();
    month = widget.subs.today.monthStart;
    refresh();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active &&
        (!oldWidget.active ||
            _fxVersion != widget.subs.dataVersion ||
            _fxDay != widget.subs.today ||
            widget.fx.fx.stale(widget.subs.ledger.latestFx))) {
      refresh();
    }
  }

  void refresh() {
    if (!widget.active || _refreshScheduled) return;
    _refreshScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted || !widget.active) return;

      _fxVersion = widget.subs.dataVersion;
      _fxDay = widget.subs.today;

      widget.fx.refreshFx(widget.subs.payments(month, month.nextMonth));
    });
  }

  void move(int n) {
    setState(() {
      month = Day.fromLocal(DateTime.utc(month.year, month.month + n, 1));
      selected = null;
    });
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.subs;
    prepareMonth();
    final payments = _payments;
    final spending = _spending!;
    final visible = selected == null
        ? payments
        : (_byDay[selected] ?? const <Payment>[]);
    final days = month.daysUntil(month.nextMonth);
    final offset = month.calendar.weekday - 1;
    final rows = ((offset + days) / 7).ceil();
    final paymentIndexes = {
      for (var i = 0; i < visible.length; i++) visible[i].id: i,
    };
    final header = <Widget>[
      Row(
        children: [
          const Expanded(
            child: AppText(
              'payment_calendar',
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
      const AppText('calendar_hint', style: TextStyle(color: muted)),
      const SizedBox(height: 24),
      Row(
        children: [
          IconButton(
            tooltip: context.tr('previous_month'),
            onPressed: month.year > 2000 ? () => move(-1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              monthName(month),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: context.tr('next_month'),
            onPressed: month.year < 2200 ? () => move(1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      Align(
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () {
            setState(() {
              month = c.today.monthStart;
              selected = null;
            });
            refresh();
          },
          child: const AppText('this_month'),
        ),
      ),
      Panel(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children:
                  List.generate(
                        7,
                        (i) => dateFormatter(
                          'E',
                        ).dateSymbols.SHORTWEEKDAYS[(i + 1) % 7],
                      )
                      .map(
                        (d) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            for (var row = 0; row < rows; row++)
              Row(
                children: List.generate(7, (col) {
                  final number = row * 7 + col - offset + 1;
                  if (number < 1 || number > days) {
                    return const Expanded(child: SizedBox(height: 64));
                  }
                  final date = Day(month.year, month.month, number);
                  final onDay = _byDay[date] ?? const <Payment>[];
                  final chosen = date == selected;
                  final today = date == c.today;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      label: context.plural(
                        'payments_count',
                        onDay.length,
                        namedArgs: {'date': prettyDay(date, year: true)},
                      ),
                      child: InkWell(
                        onTap: () => setState(() {
                          selected = chosen ? null : date;
                        }),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 64,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: chosen
                                ? ink
                                : today
                                ? mint
                                : paper.withValues(alpha: .6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$number',
                                style: TextStyle(
                                  color: chosen ? Colors.white : ink,
                                  fontWeight: today || chosen
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (onDay.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ServiceGlyph(
                                      onDay.first.snapshot.icon,
                                      size: 13,
                                      color: chosen ? Colors.white : accent,
                                    ),
                                    if (onDay.length > 1)
                                      Text(
                                        '+${onDay.length - 1}',
                                        style: TextStyle(
                                          color: chosen ? Colors.white : muted,
                                          fontSize: 8,
                                        ),
                                      ),
                                  ],
                                )
                              else
                                const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Panel(
        color: mint,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    spending.missing > 0
                        ? 'month_total_incomplete'
                        : 'month_total_estimates',
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${spending.remaining > 0 ? '~' : ''}${money(spending.total, c.ledger.displayCurrency)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.plural('payments_month_count', payments.length),
                    style: const TextStyle(fontSize: 12, color: accent),
                  ),
                ],
              ),
            ),
            const Icon(Icons.event_note_outlined, size: 32, color: accent),
          ],
        ),
      ),
      FxNote(widget.fx, missing: spending.missing),
      SectionTitle(
        selected == null
            ? context.tr('month_payments')
            : context.tr(
                'payments_date',
                namedArgs: {'date': prettyDay(selected!)},
              ),
        translate: false,
        trailing: selected == null
            ? null
            : TextButton(
                onPressed: () => setState(() {
                  selected = null;
                }),
                child: const AppText('show_all'),
              ),
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          sliver: SliverList(delegate: SliverChildListDelegate(header)),
        ),
        if (visible.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Panel(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: EmptyState(
                  'breathing_room',
                  'no_payments',
                  icon: Icons.event_available_outlined,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: DecoratedSliver(
              decoration: bubbleSurfaceDecoration(),
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final payment = visible[index];
                      return PaymentRow(
                        payment,
                        c,
                        key: ValueKey(payment.id),
                        onTap:
                            c.ledger.subscriptions.containsKey(
                              payment.subscriptionId,
                            )
                            ? () => openDetails(
                                context,
                                c,
                                payment.subscriptionId,
                              )
                            : null,
                      );
                    },
                    childCount: visible.length,
                    findChildIndexCallback: (key) {
                      if (key is! ValueKey<String>) return null;
                      return paymentIndexes[key.value];
                    },
                  ),
                ),
              ),
            ),
          ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 30),
          sliver: SliverToBoxAdapter(
            child: AppText(
              'history_note',
              style: TextStyle(color: muted, fontSize: 11, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
