import 'package:flutter/material.dart';
import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/show_error.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';
import 'package:subbles/features/fx/application/fx_controller.dart';

class CurrencySelector extends StatelessWidget {
  final FxController fx;
  final VoidCallback? onChanged;

  const CurrencySelector(this.fx, {super.key, this.onChanged});

  Future<void> select(BuildContext context, String value) async {
    try {
      await fx.selectCurrency(value);
      onChanged?.call();
    } catch (_) {
      if (context.mounted) {
        showError(context, 'currency_save_failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = fx.subscriptions.ledger.displayCurrency;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xF7FBFCF9)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Color(0x5520362F)),
        elevation: const WidgetStatePropertyAll(10),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: .9)),
          ),
        ),
      ),
      menuChildren: [
        for (final c in Currency.supported)
          MenuItemButton(
            onPressed: () => select(context, c.code),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(112, 40)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 14),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              backgroundColor: WidgetStatePropertyAll(
                c.code == current
                    ? mint.withValues(alpha: .7)
                    : Colors.transparent,
              ),
              overlayColor: WidgetStatePropertyAll(
                accent.withValues(alpha: .08),
              ),
              foregroundColor: const WidgetStatePropertyAll(ink),
              textStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 13,
                  fontWeight: c.code == current
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
              ),
            ),
            trailingIcon: c.code == current
                ? const Icon(Icons.check_rounded, size: 16, color: accent)
                : null,
            child: Text(c.code),
          ),
      ],
      builder: (context, menu, _) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          decoration: bubbleSurfaceDecoration(radius: 100, shadow: false),
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () => menu.isOpen ? menu.close() : menu.open(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    current,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  AnimatedRotation(
                    turns: menu.isOpen ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
