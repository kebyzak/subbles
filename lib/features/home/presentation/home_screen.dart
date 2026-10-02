import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/localization/language_selector.dart';
import 'package:subbles/features/subscriptions/presentation/formatters.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/empty_state.dart';
import 'package:subbles/core/widgets/service_icon.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';
import 'package:subbles/features/home/presentation/widgets/bubble_field.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_details.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_editor.dart';

class HomeScreen extends StatelessWidget {
  final SubscriptionsController subs;

  const HomeScreen(this.subs, {super.key});

  void showSubscriptions(BuildContext context) {
    final pageContext = context;
    final subscriptions = subs.ledger.subscriptions.values.toList();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ink.withValues(alpha: .2),
      builder: (sheet) => DraggableScrollableSheet(
        initialChildSize: .6,
        maxChildSize: .9,
        minChildSize: .3,
        expand: false,
        builder: (_, scroll) => BubbleSheetSurface(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            itemCount: subscriptions.isEmpty ? 2 : subscriptions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BubbleSheetHandle(),
                    SizedBox(height: 24),
                    AppText(
                      'all_subscriptions',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                );
              }
              if (subscriptions.isEmpty) {
                return const EmptyState('universe_start', 'add_using_button');
              }

              final subscription = subscriptions[index - 1];
              return Padding(
                key: ValueKey(subscription.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: bubbleSurfaceDecoration(radius: 20),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: ServiceIcon(subscription.terms.icon),
                      title: Text(
                        subscription.terms.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        subscription.terms.active
                            ? recurrenceText(
                                context,
                                subscription.terms.recurrence,
                              )
                            : context.tr('inactive_history'),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      trailing: Text(
                        original(subscription.terms),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheet);
                        openDetails(pageContext, subs, subscription.id);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = subs.active;
    final upcoming = active.map((s) => (s, s.nextPayment(subs.today)!)).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    final _ = active
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
    return Stack(
      children: [
        Positioned(
          top: upcoming.isEmpty ? 76 : 160,
          bottom: 64,
          left: 0,
          right: 0,
          child: RepaintBoundary(
            child: BubbleField(
              subscriptions: active,
              fx: subs.ledger.latestFx,
              currency: subs.ledger.displayCurrency,
              onTap: (id) => openDetails(context, subs, id),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 20,
          right: 12,
          child: Row(
            children: [
              const Expanded(
                child: AppText(
                  'subscriptions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.75,
                    color: ink,
                  ),
                ),
              ),
              const LanguageSelector(),
              const SizedBox(width: 4),
              IconButton(
                tooltip: context.tr('all_subscriptions'),
                onPressed: () => showSubscriptions(context),
                icon: const Icon(Icons.tune_rounded, size: 20, color: ink),
              ),
            ],
          ),
        ),
        if (upcoming.isNotEmpty)
          Positioned(
            top: 64,
            left: 0,
            right: 0,
            height: 92,
            child: LayoutBuilder(
              builder: (context, constraints) => ListView.separated(
                key: const ValueKey('upcoming-strip'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final (s, day) = upcoming[index];
                  final days = subs.today.daysUntil(day);
                  return SizedBox(
                    width: ((constraints.maxWidth - 52) / 2)
                        .clamp(140.0, 260.0)
                        .toDouble(),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        decoration: bubbleSurfaceDecoration(radius: 16),
                        child: InkWell(
                          onTap: () => openDetails(context, subs, s.id),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    ServiceGlyph(s.terms.icon, size: 18),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        s.terms.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  days == 0
                                      ? context.tr('payment_today')
                                      : context.plural('payment_in_days', days),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                    'universe_start',
                    'add_and_move',
                    icon: Icons.bubble_chart_outlined,
                  ),
                  FilledButton.icon(
                    onPressed: () => openEditor(context, subs),
                    icon: const Icon(Icons.add),
                    label: const AppText('add_first'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
