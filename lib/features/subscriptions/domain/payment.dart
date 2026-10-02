import 'package:subbles/core/domain/day.dart';
import 'package:subbles/features/subscriptions/domain/terms.dart';

enum PaymentType { historical, projected }

class Payment {
  final String id, subscriptionId;
  final Day date;
  final Terms snapshot;
  final PaymentType type;
  final DateTime createdAt;

  const Payment(
    this.id,
    this.subscriptionId,
    this.date,
    this.snapshot,
    this.type,
    this.createdAt,
  );

  int get amountMinor => snapshot.amountMinor;

  String get currency => snapshot.currency;

  bool get historical => type == PaymentType.historical;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subscriptionId': subscriptionId,
    'date': '$date',
    'snapshot': snapshot.toJson(),
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    j['id'],
    j['subscriptionId'],
    Day.parse(j['date']),
    Terms.fromJson(j['snapshot']),
    PaymentType.values.byName(j['type']),
    DateTime.parse(j['createdAt']),
  );
}
