import 'dart:math' as math;

import 'package:subbles/core/domain/day.dart';

enum IntervalUnit { days, weeks, months, years }

class Recurrence {
  final IntervalUnit unit;
  final int every;

  const Recurrence(this.unit, this.every) : assert(every > 0);
  static const monthly = Recurrence(IntervalUnit.months, 1);

  String get label {
    if (unit == IntervalUnit.weeks && every == 1) return 'Weekly';
    if (unit == IntervalUnit.months && every == 1) return 'Monthly';
    if (unit == IntervalUnit.years && every == 1) return 'Yearly';
    return 'Every $every ${unit.name}';
  }

  Day at(Day anchor, int index) {
    if (unit == IntervalUnit.days || unit == IntervalUnit.weeks) {
      return anchor.plusDays(
        index * every * (unit == IntervalUnit.weeks ? 7 : 1),
      );
    }
    final months = index * every * (unit == IntervalUnit.years ? 12 : 1);
    final start = DateTime.utc(anchor.year, anchor.month + months, 1);
    final last = DateTime.utc(start.year, start.month + 1, 0).day;
    return Day(start.year, start.month, math.min(anchor.day, last));
  }

  Iterable<Day> between(Day anchor, Day from, Day until) sync* {
    if (!(from < until)) return;
    int index;
    if (unit == IntervalUnit.days || unit == IntervalUnit.weeks) {
      final step = every * (unit == IntervalUnit.weeks ? 7 : 1);
      index = math.max(0, anchor.daysUntil(from) ~/ step);
    } else {
      final months = (from.year - anchor.year) * 12 + from.month - anchor.month;
      index = math.max(
        0,
        months ~/ (every * (unit == IntervalUnit.years ? 12 : 1)),
      );
    }
    for (; ; index++) {
      final date = at(anchor, index);
      if (!(date < until)) break;
      if (from <= date) yield date;
    }
  }

  Map<String, dynamic> toJson() => {'unit': unit.name, 'every': every};

  factory Recurrence.fromJson(Map<String, dynamic> j) =>
      Recurrence(IntervalUnit.values.byName(j['unit']), j['every']);

  @override
  bool operator ==(Object other) =>
      other is Recurrence && unit == other.unit && every == other.every;

  @override
  int get hashCode => Object.hash(unit, every);
}
