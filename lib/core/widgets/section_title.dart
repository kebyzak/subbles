import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool translate;
  const SectionTitle(
    this.title, {
    super.key,
    this.trailing,
    this.translate = true,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            translate ? context.tr(title) : title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
