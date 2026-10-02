import 'package:flutter/material.dart';
import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/core/domain/day.dart';
import 'package:subbles/core/domain/recurrence.dart';
import 'package:subbles/core/format/date_format.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/features/subscriptions/application/subscriptions_controller.dart';
import 'package:subbles/features/subscriptions/domain/subscription.dart';
import 'package:subbles/features/subscriptions/domain/terms.dart';
import 'package:subbles/features/subscriptions/presentation/widgets/service_icons.dart';

Future<void> openEditor(
  BuildContext context,
  SubscriptionsController subs, {
  Subscription? subscription,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: paper,
  builder: (_) => SubscriptionEditor(subs, subscription: subscription),
);

class SubscriptionEditor extends StatefulWidget {
  final SubscriptionsController subs;
  final Subscription? subscription;

  const SubscriptionEditor(this.subs, {super.key, this.subscription});

  @override
  State<SubscriptionEditor> createState() => _SubscriptionEditorState();
}

class _SubscriptionEditorState extends State<SubscriptionEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, price, notes, interval;
  late String icon, currency, category, frequency;
  late IntervalUnit customUnit;
  late Day date, initialDate;
  late bool active;
  bool saving = false;
  String? failure;
  static const frequencies = [
    'Weekly',
    'Monthly',
    'Every 3 months',
    'Every 6 months',
    'Yearly',
    'Custom interval',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.subscription?.terms;
    name = TextEditingController(text: t?.name ?? '');
    price = TextEditingController(
      text: t == null
          ? ''
          : Currency.get(t.currency).major(t.amountMinor).toStringAsFixed(2),
    );
    notes = TextEditingController(text: t?.notes ?? '');
    interval = TextEditingController(text: '${t?.recurrence.every ?? 1}');
    icon = t?.icon ?? serviceIcons.first;
    currency = t?.currency ?? widget.subs.ledger.displayCurrency;
    category = t?.category ?? 'Entertainment';
    active = t?.active ?? true;
    customUnit = t?.recurrence.unit ?? IntervalUnit.months;
    frequency = t == null
        ? 'Monthly'
        : (frequencies.contains(t.recurrence.label)
              ? t.recurrence.label
              : 'Custom interval');
    date = t == null
        ? widget.subs.today
        : Subscription(
            'temp',
            t.withActive(true),
            DateTime.now(),
            DateTime.now(),
          ).nextPayment(widget.subs.today)!;
    initialDate = date;
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    notes.dispose();
    interval.dispose();
    super.dispose();
  }

  Recurrence get recurrence => switch (frequency) {
    'Weekly' => const Recurrence(IntervalUnit.weeks, 1),
    'Monthly' => Recurrence.monthly,
    'Every 3 months' => const Recurrence(IntervalUnit.months, 3),
    'Every 6 months' => const Recurrence(IntervalUnit.months, 6),
    'Yearly' => const Recurrence(IntervalUnit.years, 1),
    _ => Recurrence(customUnit, int.parse(interval.text)),
  };

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      failure = null;
    });
    try {
      final old = widget.subscription?.terms;
      final rule = recurrence;
      final anchor =
          old != null && date == initialDate && rule == old.recurrence
          ? old.anchor
          : date;
      await widget.subs.saveSubscription(
        Terms(
          name: name.text.trim(),
          icon: icon,
          amountMinor: Currency.get(currency).parse(price.text),
          currency: currency,
          recurrence: rule,
          anchor: anchor,
          category: category,
          notes: notes.text.trim(),
          active: active,
        ),
        id: widget.subscription?.id,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          failure =
              'Could not save. Your previous data is unchanged. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: DraggableScrollableSheet(
      initialChildSize: .91,
      minChildSize: .6,
      maxChildSize: .96,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.subscription == null
                          ? 'Add subscription'
                          : 'Edit subscription',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'A little clarity for your recurring costs.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: serviceIcons
                    .map(
                      (value) => InkWell(
                        onTap: () => setState(() {
                          icon = value;
                        }),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: icon == value ? mint : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: icon == value
                                  ? accent
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontFamilyFallback: emojiFonts,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Apple Music',
                ),
                maxLength: 60,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a subscription name'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Price'),
                      validator: (v) {
                        try {
                          Currency.get(currency).parse(v ?? '');
                          return null;
                        } on FormatException catch (e) {
                          return e.message;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: Currency.supported
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.code,
                              child: Text(c.code),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        currency = v!;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: frequency,
                decoration: const InputDecoration(
                  labelText: 'Billing frequency',
                ),
                items: frequencies
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() {
                  frequency = v!;
                }),
              ),
              if (frequency == 'Custom interval')
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: interval,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Every'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return n == null || n < 1 || n > 120
                                ? 'Use 1–120'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<IntervalUnit>(
                          initialValue: customUnit,
                          items: IntervalUnit.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            customUnit = v!;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(date.year, date.month, date.day),
                    firstDate: widget.subscription == null
                        ? DateTime(2000)
                        : DateTime(
                            widget.subs.today.year,
                            widget.subs.today.month,
                            widget.subs.today.day,
                          ),
                    lastDate: DateTime(2200),
                  );
                  if (picked != null) {
                    setState(() {
                      date = Day.fromLocal(picked);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Next payment date',
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(prettyDay(date, year: true))),
                      const Icon(Icons.calendar_today_outlined, size: 20),
                    ],
                  ),
                ),
              ),
              if (date < widget.subs.today)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Past dates will record scheduled payments from this date at the entered price. These are assumed charges, not bank-confirmed payments.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.subs.ledger.categories
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() {
                  category = v!;
                }),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: notes,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              if (widget.subscription != null)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active subscription'),
                  subtitle: const Text(
                    'Inactive subscriptions keep their history.',
                  ),
                  value: active,
                  onChanged: (v) => setState(() {
                    active = v;
                  }),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Changes apply from today. Earlier payments keep their original terms.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
              if (failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    failure!,
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(
                    saving
                        ? 'Saving…'
                        : widget.subscription == null
                        ? 'Add subscription'
                        : 'Save changes',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
