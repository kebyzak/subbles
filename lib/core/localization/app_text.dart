import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:subbles/core/domain/recurrence.dart';

export 'package:easy_localization/easy_localization.dart';

const appLocales = [Locale('kk'), Locale('en'), Locale('ru')];

class AppLocalization extends StatelessWidget {
  final Widget child;

  const AppLocalization({super.key, required this.child});

  @override
  Widget build(BuildContext context) => EasyLocalization(
    supportedLocales: appLocales,
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
    saveLocale: true,
    ignorePluralRules: false,
    child: child,
  );
}

class AppText extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) => Text(
    context.tr(translationKey),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}

String recurrenceText(BuildContext context, Recurrence recurrence) {
  if (recurrence.every == 1) {
    final key = switch (recurrence.unit) {
      IntervalUnit.weeks => 'weekly',
      IntervalUnit.months => 'monthly',
      IntervalUnit.years => 'yearly',
      IntervalUnit.days => null,
    };
    if (key != null) return context.tr(key);
  }
  return context.plural('recurrence_${recurrence.unit.name}', recurrence.every);
}

String frequencyText(BuildContext context, String frequency) =>
    context.tr(switch (frequency) {
      'Weekly' => 'weekly',
      'Monthly' => 'monthly',
      'Every 3 months' => 'every_3_months',
      'Every 6 months' => 'every_6_months',
      'Yearly' => 'yearly',
      _ => 'custom_interval',
    });

String categoryText(BuildContext context, String category) {
  final key = switch (category) {
    'Entertainment' => 'category_entertainment',
    'Cloud storage' => 'category_cloud',
    'Productivity' => 'category_productivity',
    'Utilities' => 'category_utilities',
    'Education' => 'category_education',
    'AI' => 'category_ai',
    'Other' => 'category_other',
    _ => null,
  };
  return key == null ? category : context.tr(key);
}
