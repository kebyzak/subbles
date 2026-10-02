import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/domain/recurrence.dart';

class Terms {
  final String name, icon, currency, category, notes;
  final int amountMinor;
  final Recurrence recurrence;
  final Day anchor;
  final bool active;

  const Terms({
    required this.name,
    required this.icon,
    required this.amountMinor,
    required this.currency,
    required this.recurrence,
    required this.anchor,
    required this.category,
    this.notes = '',
    this.active = true,
  });

  Terms withActive(bool value) => Terms(
    name: name,
    icon: icon,
    amountMinor: amountMinor,
    currency: currency,
    recurrence: recurrence,
    anchor: anchor,
    category: category,
    notes: notes,
    active: value,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'amountMinor': amountMinor,
    'currency': currency,
    'recurrence': recurrence.toJson(),
    'anchor': '$anchor',
    'category': category,
    'notes': notes,
    'active': active,
  };

  factory Terms.fromJson(Map<String, dynamic> j) => Terms(
    name: j['name'],
    icon: j['icon'],
    amountMinor: j['amountMinor'],
    currency: j['currency'],
    recurrence: Recurrence.fromJson(j['recurrence']),
    anchor: Day.parse(j['anchor']),
    category: j['category'],
    notes: j['notes'],
    active: j['active'],
  );
}
