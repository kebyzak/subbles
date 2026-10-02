import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/features/subscriptions/presentation/formatters.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/features/fx/domain/fx_table.dart';
import 'package:subbles/features/home/domain/bubble_physics.dart';
import 'package:subbles/features/subscriptions/domain/subscription.dart';

class BubbleField extends StatefulWidget {
  final List<Subscription> subscriptions;
  final FxTable? fx;
  final String currency;
  final void Function(String id) onTap;

  const BubbleField({
    super.key,
    required this.subscriptions,
    required this.fx,
    required this.currency,
    required this.onTap,
  });

  @override
  State<BubbleField> createState() => _BubbleFieldState();
}

class _BubbleFieldState extends State<BubbleField>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  BubblePhysics world = BubblePhysics([], Size.zero);
  Duration last = Duration.zero;
  Duration? dragTime;
  String signature = '';

  @override
  void initState() {
    super.initState();
    ticker = createTicker(tick)..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void synchronize(Size size) {
    final nextSignature =
        '${widget.currency}|${widget.fx?.retrievedAt}|$size|${widget.subscriptions.map((s) => '${s.id}:${s.terms.hashCode}').join(',')}';
    if (signature == nextSignature) return;
    signature = nextSignature;
    final previous = {for (final b in world.bodies) b.id: b};
    final values = widget.subscriptions
        .map(
          (s) => s.terms.currency == widget.currency
              ? Currency.get(widget.currency).major(s.terms.amountMinor)
              : widget.fx?.convert(
                  s.terms.amountMinor,
                  s.terms.currency,
                  widget.currency,
                ),
        )
        .toList();
    final maximum = values.whereType<double>().fold<double>(0, math.max);
    final wantedArea = values.fold<double>(0, (sum, value) {
      final r = value == null || maximum <= 0
          ? 50.0
          : 40 + 28 * math.sqrt(value / maximum);
      return sum + math.pi * r * r;
    });
    final densityScale = math.min(
      1.0,
      math.sqrt(size.width * size.height * .38 / math.max(1, wantedArea)),
    );
    final bodies = <BubbleBody>[];
    world = BubblePhysics(bodies, size);
    for (var i = 0; i < widget.subscriptions.length; i++) {
      final s = widget.subscriptions[i], value = values[i];
      final base = value == null || maximum <= 0
          ? 50.0
          : 40 + 28 * math.sqrt(value / maximum);
      final radius = math.max(32.0, base * densityScale);
      final old = previous[s.id];
      // Deterministic scattered placement gives the canvas room to breathe.
      final x = .18 + ((i * .61803398875) % 1) * .64;
      final y = .25 + ((i * .38196601125) % 1) * .57;
      final body = BubbleBody(
        s.id,
        radius,
        world.contain(
          old?.position ?? Offset(size.width * x, size.height * y),
          radius,
        ),
        old?.velocity ??
            Offset(math.cos(i * 2.4 + .6), math.sin(i * 2.4 + .6)) * 14.25,
      );
      body.held = old?.held ?? false;
      bodies.add(body);
    }
  }

  void tick(Duration elapsed) {
    final dt = (elapsed - last).inMicroseconds / 1000000;
    last = elapsed;
    if (world.bodies.isEmpty || !mounted) return;
    world.step(dt);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      synchronize(Size(constraints.maxWidth, constraints.maxHeight));
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Quiet background bubbles match the airy reference without gesture targets.
          for (final item in [
            (const Offset(.42, .21), 16.0),
            (const Offset(.78, .54), 13.0),
            (const Offset(.28, .84), 18.0),
          ])
            Positioned(
              left: world.size.width * item.$1.dx,
              top: world.size.height * item.$1.dy,
              child: IgnorePointer(
                child: Container(
                  width: item.$2 * 2,
                  height: item.$2 * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5F4F7),
                    border: Border.all(
                      color: const Color(0xFFEFEDF1),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          for (var i = 0; i < world.bodies.length; i++)
            bubble(world.bodies[i], widget.subscriptions[i]),
        ],
      );
    },
  );

  Widget bubble(BubbleBody body, Subscription subscription) => Positioned(
    key: ValueKey('bubble-${body.id}'),
    left: body.position.dx - body.radius,
    top: body.position.dy - body.radius,
    width: body.radius * 2,
    height: body.radius * 2,
    child: Semantics(
      button: true,
      label: '${subscription.terms.name}, ${original(subscription.terms)}',
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        onTap: () => widget.onTap(body.id),
        onPanStart: (event) {
          body.held = true;
          body.velocity = Offset.zero;
          dragTime = event.sourceTimeStamp;
        },
        onPanUpdate: (event) {
          final timestamp = event.sourceTimeStamp;
          final dt = timestamp == null || dragTime == null
              ? 1 / 60
              : ((timestamp - dragTime!).inMicroseconds / 1000000).clamp(
                  1 / 240,
                  1 / 20,
                );
          dragTime = timestamp;
          setState(() {
            body.position = world.contain(
              body.position + event.delta,
              body.radius,
            );
            body.velocity = BubblePhysics.limit(event.delta / dt);
          });
        },
        onPanEnd: (event) {
          body.held = false;
          dragTime = null;
          final fling = event.velocity.pixelsPerSecond;
          body.velocity = BubblePhysics.limit(
            fling.distance > 30 ? fling * .6375 : body.velocity * .15,
          );
        },
        onPanCancel: () {
          body.held = false;
          dragTime = null;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-.25, -.35),
              colors: [Color(0xFFFEFDFE), Color(0xFFF1EFF3)],
            ),
            border: Border.all(
              color: body.held
                  ? const Color(0xFFC5C0DE)
                  : const Color(0xFFE7E4EA),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF777080,
                ).withValues(alpha: body.held ? .12 : .05),
                blurRadius: body.held ? 16 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  subscription.terms.icon,
                  style: TextStyle(
                    fontSize: body.radius * .65,
                    height: 1,
                    fontFamilyFallback: emojiFonts,
                  ),
                ),
                const SizedBox(height: 6),
                // Name remains accessible via semantics and the payment strip.
                FittedBox(
                  child: Text(
                    original(subscription.terms),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.15,
                      color: Color(0xFF29292D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
