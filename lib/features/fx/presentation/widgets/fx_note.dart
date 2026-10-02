import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';

class FxNote extends StatelessWidget {
  final FxController controller;
  final int missing;

  const FxNote(this.controller, {super.key, this.missing = 0});

  @override
  Widget build(BuildContext context) {
    final fx = controller.subscriptions.ledger.latestFx;
    final text = controller.fetchingFx
        ? 'Updating exchange rates…'
        : fx == null
        ? 'No FX cache yet. Original amounts are always available.'
        : '${controller.cachedFx || controller.fx.stale(fx) ? 'Using cached rates' : 'FX updated'} ${DateFormat('d MMM, HH:mm').format(fx.retrievedAt.toLocal())} · rate date ${prettyDay(fx.date)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.currency_exchange_rounded,
                size: 15,
                color: muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
            ],
          ),
          if (missing > 0)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                '$missing payment${missing == 1 ? '' : 's'} missing FX. Totals, rankings, graph and shares include available conversions only.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9C6033)),
              ),
            ),
          if (controller.error != null)
            Text(
              controller.error!,
              style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
