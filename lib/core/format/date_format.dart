import 'package:intl/intl.dart';
import 'package:subbles/core/domain/day.dart';

final _dateFormats = <(String, String), DateFormat>{};

DateFormat dateFormatter(String pattern) {
  final locale = Intl.getCurrentLocale();

  return _dateFormats.putIfAbsent((
    locale,
    pattern,
  ), () => DateFormat(pattern, locale));
}

String prettyDay(Day date, {bool year = false}) =>
    dateFormatter(year ? 'd MMM yyyy' : 'd MMM').format(date.calendar);

String monthName(Day date) => dateFormatter('MMMM yyyy').format(date.calendar);
