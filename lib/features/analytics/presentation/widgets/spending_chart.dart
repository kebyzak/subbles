import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/features/analytics/domain/spending.dart';

class SpendingChart extends StatelessWidget {
  final Spending spending;
  final Day from, until;
  final bool yearly;

  const SpendingChart(
    this.spending,
    this.from,
    this.until,
    this.yearly, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final buckets = yearly
        ? List.generate(12, (i) => Day(from.year, i + 1, 1))
        : List.generate(from.daysUntil(until), (i) => from.plusDays(i));
    final maxValue = buckets.fold<double>(
      1,
      (v, date) => math.max(
        v,
        (spending.actualGraph[date] ?? 0) +
            (spending.projectedGraph[date] ?? 0),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: buckets.asMap().entries.map((entry) {
        final date = entry.value;
        final actual = spending.actualGraph[date] ?? 0,
            estimated = spending.projectedGraph[date] ?? 0;
        return Expanded(
          child: Tooltip(
            message: context.tr(
              'chart_tooltip',
              namedArgs: {
                'date': prettyDay(date),
                'actual': actual.toStringAsFixed(2),
                'estimated': estimated.toStringAsFixed(2),
              },
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: yearly ? 3 : 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: estimated / maxValue * 145,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7C8B5),
                      borderRadius: actual == 0
                          ? BorderRadius.circular(4)
                          : const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                    ),
                  ),
                  Container(
                    height: actual / maxValue * 145,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: estimated == 0
                          ? BorderRadius.circular(4)
                          : const BorderRadius.vertical(
                              bottom: Radius.circular(4),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 16,
                    child: Text(
                      yearly
                          ? dateFormatter(
                              'M',
                            ).dateSymbols.NARROWMONTHS[entry.key]
                          : entry.key % 5 == 0 ||
                                entry.key == buckets.length - 1
                          ? '${date.day}'
                          : '',
                      style: const TextStyle(fontSize: 9, color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
