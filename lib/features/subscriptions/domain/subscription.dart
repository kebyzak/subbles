import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/subscriptions/domain/terms.dart';

class Subscription {
  final String id;
  final Terms terms;
  final DateTime createdAt, updatedAt;

  const Subscription(this.id, this.terms, this.createdAt, this.updatedAt);

  Day? nextPayment(Day today) {
    if (!terms.active) return null;
    return terms.recurrence
        .between(terms.anchor, today, today.plusDays(366000))
        .firstOrNull;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'terms': terms.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    j['id'],
    Terms.fromJson(j['terms']),
    DateTime.parse(j['createdAt']),
    DateTime.parse(j['updatedAt']),
  );
}
