import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';

class FxNote extends StatelessWidget {
  final FxController controller;
  final int missing;

  const FxNote(this.controller, {super.key, this.missing = 0});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => buildContent(context),
  );

  Widget buildContent(BuildContext context) {
    final fx = controller.subscriptions.ledger.latestFx;
    final text = controller.fetchingFx
        ? context.tr('updating_fx')
        : fx == null
        ? context.tr('no_fx_cache')
        : context.tr(
            'fx_timestamp',
            namedArgs: {
              'status': context.tr(
                controller.cachedFx || controller.fx.stale(fx)
                    ? 'cached_rates'
                    : 'fx_updated',
              ),
              'time': dateFormatter(
                'd MMM, HH:mm',
              ).format(fx.retrievedAt.toLocal()),
              'date': prettyDay(fx.date),
            },
          );
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
                context.plural('missing_fx_count', missing),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9C6033)),
              ),
            ),
          if (controller.error != null)
            AppText(
              controller.error!,
              style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
