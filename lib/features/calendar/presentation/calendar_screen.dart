import 'package:flutter/material.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/format/money_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/empty_state.dart';
import 'package:subbles/core/widgets/panel.dart';
import 'package:subbles/core/widgets/section_title.dart';
import 'package:subbles/features/analytics/domain/spending.dart';
import 'package:subbles/features/fx/presentation/widgets/currency_selector.dart';
import 'package:subbles/features/fx/presentation/widgets/fx_note.dart';
import 'package:subbles/features/subscriptions/presentation/widgets/payment_row.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_details.dart';

class CalendarScreen extends StatefulWidget {
  final SubscriptionsController subs;
  final FxController fx;

  const CalendarScreen(this.subs, this.fx, {super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Day month;
  Day? selected;

  @override
  void initState() {
    super.initState();
    month = widget.subs.today.monthStart;
    refresh();
  }

  void refresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.fx.refreshFx(widget.subs.payments(month, month.nextMonth));
      }
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
    final payments = c.payments(month, month.nextMonth);
    final spending = Spending.calculate(
      payments,
      c.ledger,
      c.ledger.displayCurrency,
    );
    final visible = selected == null
        ? payments
        : payments.where((p) => p.date == selected).toList();
    final days = month.daysUntil(month.nextMonth);
    final offset = month.calendar.weekday - 1;
    final rows = ((offset + days) / 7).ceil();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Payment calendar',
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
          'Every payment, past and possible.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: month.year > 2000 ? () => move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                monthName(month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
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
            child: const Text('This month'),
          ),
        ),
        Panel(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map(
                      (d) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: muted, fontSize: 12),
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
                    final onDay = payments
                        .where((p) => p.date == date)
                        .toList();
                    final chosen = date == selected;
                    final today = date == c.today;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        label:
                            '${prettyDay(date, year: true)}, ${onDay.length} payments',
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
                                      Text(
                                        onDay.first.snapshot.icon,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamilyFallback: emojiFonts,
                                        ),
                                      ),
                                      if (onDay.length > 1)
                                        Text(
                                          '+${onDay.length - 1}',
                                          style: TextStyle(
                                            color: chosen
                                                ? Colors.white
                                                : muted,
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
                    Text(
                      spending.missing > 0
                          ? 'MONTH TOTAL · INCOMPLETE'
                          : 'MONTH TOTAL · INCLUDES ESTIMATES',
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
                      '${payments.length} payments this month',
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
              ? 'This month’s payments'
              : 'Payments · ${prettyDay(selected!)}',
          trailing: selected == null
              ? null
              : TextButton(
                  onPressed: () => setState(() {
                    selected = null;
                  }),
                  child: const Text('Show all'),
                ),
        ),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: visible.isEmpty
              ? const EmptyState(
                  'A little breathing room',
                  'No payments scheduled here.',
                  icon: Icons.event_available_outlined,
                )
              : Column(
                  children: visible
                      .map(
                        (p) => PaymentRow(
                          p,
                          c,
                          onTap:
                              c.ledger.subscriptions.containsKey(
                                p.subscriptionId,
                              )
                              ? () => openDetails(context, c, p.subscriptionId)
                              : null,
                        ),
                      )
                      .toList(),
                ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Historical entries reflect your saved subscription schedule. Projected entries use current terms; future FX values are estimates.',
            style: TextStyle(color: muted, fontSize: 11, height: 1.5),
          ),
        ),
      ],
    );
  }
}
