class Day implements Comparable<Day> {
  final int year, month, day;

  const Day(this.year, this.month, this.day);

  factory Day.today() => Day.fromLocal(DateTime.now());

  factory Day.fromLocal(DateTime d) => Day(d.year, d.month, d.day);

  factory Day.parse(String s) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      throw const FormatException('Expected YYYY-MM-DD');
    }
    final p = s.split('-').map(int.parse).toList();
    final check = DateTime.utc(p[0], p[1], p[2]);
    if (p[0] < 1 ||
        check.year != p[0] ||
        check.month != p[1] ||
        check.day != p[2]) {
      throw const FormatException('Invalid calendar date');
    }
    return Day(p[0], p[1], p[2]);
  }

  DateTime get calendar => DateTime.utc(year, month, day);

  Day plusDays(int n) {
    final d = calendar.add(Duration(days: n));
    return Day(d.year, d.month, d.day);
  }

  Day get monthStart => Day(year, month, 1);

  Day get nextMonth => Day.fromLocal(DateTime.utc(year, month + 1, 1));

  int daysUntil(Day other) => other.calendar.difference(calendar).inDays;

  @override
  int compareTo(Day other) => calendar.compareTo(other.calendar);

  bool operator <(Day other) => compareTo(other) < 0;

  bool operator <=(Day other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) => other is Day && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
