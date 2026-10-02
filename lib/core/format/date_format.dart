import 'package:intl/intl.dart';
import 'package:subbles/core/domain/day.dart';

String prettyDay(Day date, {bool year = false}) =>
    DateFormat(year ? 'd MMM yyyy' : 'd MMM').format(date.calendar);

String monthName(Day date) => DateFormat('MMMM yyyy').format(date.calendar);
