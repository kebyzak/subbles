import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: bubbleSurfaceDecoration(radius: 100, shadow: false),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: Locale(context.locale.languageCode),
        isDense: true,
        borderRadius: BorderRadius.circular(20),
        dropdownColor: const Color(0xF5F3F6F0),
        padding: const EdgeInsets.symmetric(vertical: 8),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: muted, size: 20),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        hint: const AppText('language'),
        items: const [
          DropdownMenuItem(value: Locale('kk'), child: Text('Қазақша')),
          DropdownMenuItem(value: Locale('en'), child: Text('English')),
          DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
        ],
        onChanged: (locale) async {
          if (locale != null && locale != context.locale) {
            await context.setLocale(locale);
          }
        },
      ),
    ),
  );
}
