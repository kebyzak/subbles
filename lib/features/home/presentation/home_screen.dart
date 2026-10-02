import 'package:flutter/material.dart';
import 'package:subbles/features/subscriptions/presentation/formatters.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/empty_state.dart';
import 'package:subbles/core/widgets/service_icon.dart';
import 'package:subbles/features/fx/presentation/widgets/currency_selector.dart';
import 'package:subbles/features/home/presentation/widgets/bubble_field.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_details.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_editor.dart';

class HomeScreen extends StatelessWidget {
  final SubscriptionsController subs;
  final FxController fx;

  const HomeScreen(this.subs, this.fx, {super.key});

  void showSubscriptions(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: paper,
    builder: (sheet) => DraggableScrollableSheet(
      initialChildSize: .6,
      maxChildSize: .9,
      minChildSize: .3,
      expand: false,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'All subscriptions',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (subs.ledger.subscriptions.isEmpty)
            const EmptyState(
              'Your universe starts here',
              'Add a subscription using the + button.',
            ),
          for (final s in subs.ledger.subscriptions.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ServiceIcon(s.terms.icon),
              title: Text(s.terms.name),
              subtitle: Text(
                s.terms.active
                    ? s.terms.recurrence.label
                    : 'Inactive · history preserved',
              ),
              trailing: Text(
                original(s.terms),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(sheet);
                openDetails(context, subs, s.id);
              },
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final active = subs.active;
    final upcoming = active.map((s) => (s, s.nextPayment(subs.today)!)).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    final missing = active
        .where(
          (s) =>
              s.terms.currency != subs.ledger.displayCurrency &&
              subs.ledger.latestFx?.convert(
                    s.terms.amountMinor,
                    s.terms.currency,
                    subs.ledger.displayCurrency,
                  ) ==
                  null,
        )
        .length;
    return ColoredBox(
      color: const Color(0xFFFEFDFE),
      child: Stack(
        children: [
          Positioned.fill(
            child: BubbleField(
              subscriptions: active,
              fx: subs.ledger.latestFx,
              currency: subs.ledger.displayCurrency,
              onTap: (id) => openDetails(context, subs, id),
            ),
          ),
          Positioned(
            top: 8,
            left: 18,
            right: 12,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Subscriptions',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF29292D),
                    ),
                  ),
                ),
                CurrencySelector(fx),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'All subscriptions',
                  onPressed: () => showSubscriptions(context),
                  icon: const Icon(Icons.tune_rounded, size: 21),
                ),
              ],
            ),
          ),
          if (upcoming.isNotEmpty)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              height: 76,
              child: ListView.separated(
                key: const ValueKey('upcoming-strip'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final (s, day) = upcoming[index];
                  final days = subs.today.daysUntil(day);
                  return SizedBox(
                    width: 205,
                    child: Material(
                      color: const Color(0xFFF3F2F5).withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => openDetails(context, subs, s.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.terms.icon,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1,
                                      fontFamilyFallback: emojiFonts,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      s.terms.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF29292D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                days == 0
                                    ? 'Payment due today'
                                    : 'Payment due in $days ${days == 1 ? 'day' : 'days'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5D5B65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (active.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      'Your universe starts here',
                      'Add a subscription, then grab a bubble and give it a little momentum.',
                      icon: Icons.bubble_chart_outlined,
                    ),
                    FilledButton.icon(
                      onPressed: () => openEditor(context, subs),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first subscription'),
                    ),
                  ],
                ),
              ),
            ),
          if (active.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 20,
              right: 88,
              child: IgnorePointer(
                child: Text(
                  missing > 0
                      ? 'FX unavailable · $missing neutral-sized bubbles'
                      : 'Grab, move, throw',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9D9AA4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
