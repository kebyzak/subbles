import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/subscriptions/domain/terms.dart';

class Revision {
  final String id, subscriptionId;
  final Day effective;
  final Terms terms;
  final DateTime createdAt;

  const Revision(
    this.id,
    this.subscriptionId,
    this.effective,
    this.terms,
    this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'subscriptionId': subscriptionId,
    'effective': '$effective',
    'terms': terms.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Revision.fromJson(Map<String, dynamic> j) => Revision(
    j['id'],
    j['subscriptionId'],
    Day.parse(j['effective']),
    Terms.fromJson(j['terms']),
    DateTime.parse(j['createdAt']),
  );
}
