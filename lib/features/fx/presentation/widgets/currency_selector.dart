import 'package:flutter/material.dart';
import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/show_error.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';

class CurrencySelector extends StatelessWidget {
  final FxController fx;
  final VoidCallback? onChanged;

  const CurrencySelector(this.fx, {super.key, this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ink.withValues(alpha: .1)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: fx.subscriptions.ledger.displayCurrency,
        isDense: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: ink,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        items: Currency.supported
            .map((c) => DropdownMenuItem(value: c.code, child: Text(c.code)))
            .toList(),
        onChanged: (value) async {
          if (value == null) return;
          try {
            await fx.selectCurrency(value);
            onChanged?.call();
          } catch (_) {
            if (context.mounted) {
              showError(context, 'Could not save your currency preference.');
            }
          }
        },
      ),
    ),
  );
}
