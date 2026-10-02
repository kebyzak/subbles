import 'package:flutter/material.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/features/subscriptions/presentation/formatters.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/panel.dart';
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
    backgroundColor: paper,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Text(
                      '${s.terms.category} · ${s.terms.active ? 'Active' : 'Inactive'}',
                      style: const TextStyle(color: muted),
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
          Text(s.terms.recurrence.label, style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          Panel(
            child: Row(
              children: [
                const Icon(Icons.event_outlined, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.nextPayment(subs.today) == null
                        ? 'No future payments'
                        : 'Next payment · ${prettyDay(s.nextPayment(subs.today)!, year: true)}',
                  ),
                ),
              ],
            ),
          ),
          if (s.terms.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(s.terms.notes),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit subscription'),
              onPressed: () {
                Navigator.pop(sheetContext);
                openEditor(context, subs, subscription: s);
              },
            ),
          ),
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
                      showError(
                        sheetContext,
                        'Could not deactivate. Please retry.',
                      );
                    }
                  }
                },
                child: const Text('Deactivate · keep history'),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                final remove = await showDialog<bool>(
                  context: sheetContext,
                  builder: (dialog) => AlertDialog(
                    title: const Text('Delete subscription?'),
                    content: const Text(
                      'Future payments will stop. All historical payments will remain in Calendar and Analytics.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialog, false),
                        child: const Text('Keep'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialog, true),
                        child: const Text('Delete'),
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
                    showError(sheetContext, 'Could not delete. Please retry.');
                  }
                }
              },
              child: const Text(
                'Delete subscription',
                style: TextStyle(color: Color(0xFFA35447)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
