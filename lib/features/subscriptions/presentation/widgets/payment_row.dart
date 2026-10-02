import 'package:flutter/material.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/features/subscriptions/presentation/formatters.dart';
import 'package:subbles/core/format/money_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/service_icon.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/subscriptions/domain/payment.dart';

class PaymentRow extends StatelessWidget {
  final Payment payment;
  final SubscriptionsController subs;
  final VoidCallback? onTap;

  const PaymentRow(this.payment, this.subs, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final converted = subs.ledger.convert(payment, subs.ledger.displayCurrency);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            ServiceIcon(payment.snapshot.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.snapshot.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${prettyDay(payment.date)} · ${payment.snapshot.recurrence.label}',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  Text(
                    payment.historical
                        ? 'Historical · recorded schedule'
                        : 'Projected · estimate',
                    style: TextStyle(
                      fontSize: 10,
                      color: payment.historical ? accent : muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  original(payment.snapshot),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (payment.currency != subs.ledger.displayCurrency)
                  Text(
                    converted == null
                        ? 'FX unavailable'
                        : '${payment.historical ? '' : '~'}${money(converted, subs.ledger.displayCurrency)}',
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
