import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/features/subscriptions/presentation/formatters.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/panel.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';
import 'package:subbles/core/widgets/service_icon.dart';
import 'package:subbles/core/widgets/show_error.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/subscriptions/presentation/subscription_editor.dart';

Future<void> openDetails(
  BuildContext context,
  SubscriptionsController subs,
  String id,
) async {
  final s = subs.ledger.subscriptions[id];
  if (s == null) return;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: ink.withValues(alpha: .2),
    builder: (sheetContext) => BubbleSheetSurface(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BubbleSheetHandle(),
            const SizedBox(height: 24),
            Row(
              children: [
                ServiceIcon(s.terms.icon, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.terms.name,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: bubbleSurfaceDecoration(
                          radius: 100,
                          shadow: false,
                        ),
                        child: Text(
                          '${categoryText(sheetContext, s.terms.category)} · ${sheetContext.tr(s.terms.active ? 'active' : 'inactive')}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              original(s.terms),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            Text(
              recurrenceText(sheetContext, s.terms.recurrence),
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            Panel(
              child: Row(
                children: [
                  const Icon(Icons.event_outlined, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.nextPayment(subs.today) == null
                          ? sheetContext.tr('no_future')
                          : sheetContext.tr(
                              'next_payment',
                              namedArgs: {
                                'date': prettyDay(
                                  s.nextPayment(subs.today)!,
                                  year: true,
                                ),
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (s.terms.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Panel(child: Text(s.terms.notes)),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const AppText('edit_subscription'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  openEditor(context, subs, subscription: s);
                },
              ),
            ),
            const SizedBox(height: 10),
            if (s.terms.active)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await subs.deactivate(id);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    } catch (_) {
                      if (sheetContext.mounted) {
                        showError(sheetContext, 'deactivate_failed');
                      }
                    }
                  },
                  child: const AppText('deactivate'),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  final remove = await showDialog<bool>(
                    context: sheetContext,
                    barrierColor: ink.withValues(alpha: .2),
                    builder: (dialog) => AlertDialog(
                      title: const AppText('delete_question'),
                      content: const AppText('delete_note'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog, false),
                          child: const AppText('keep'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialog, true),
                          child: const AppText('delete'),
                        ),
                      ],
                    ),
                  );
                  if (remove != true) return;
                  try {
                    await subs.delete(id);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  } catch (_) {
                    if (sheetContext.mounted) {
                      showError(sheetContext, 'delete_failed');
                    }
                  }
                },
                child: const AppText(
                  'delete_subscription',
                  style: TextStyle(color: Color(0xFFA35447)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
