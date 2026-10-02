import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:subbles/core/domain/currency.dart';
import 'package:subbles/features/subscriptions/presentation/formatters.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/service_icon.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker ticker;
  BubblePhysics world = BubblePhysics([], Size.zero);
  Duration? last;
  bool _foreground = true;
  bool _tickerAllowed = true;
  bool _routeCurrent = true;
  bool _sleeping = false;
  Duration? dragTime;
  String signature = '';
  final positionsChanged = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();

    final binding = WidgetsBinding.instance;
    binding.addObserver(this);

    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;

    ticker = createTicker(tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _tickerAllowed = TickerMode.valuesOf(context).enabled;
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;

    synchronizeTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    synchronizeTicker();
  }

  void synchronizeTicker() {
    final shouldRun =
        mounted &&
        _foreground &&
        _tickerAllowed &&
        _routeCurrent &&
        !_sleeping &&
        world.bodies.isNotEmpty;

    if (shouldRun && !ticker.isActive) {
      last = null;
      ticker.start();
    } else if (!shouldRun && ticker.isActive) {
      ticker.stop();
      last = null;
    }
  }

  void wakePhysics() {
    _sleeping = false;
    synchronizeTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    positionsChanged.dispose();
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
    wakePhysics();
  }

  void tick(Duration elapsed) {
    if (!mounted || !_foreground || !_tickerAllowed || !_routeCurrent) return;

    final previous = last;
    last = elapsed;

    if (previous == null) return;

    final dt = math.min((elapsed - previous).inMicroseconds / 1000000, 1 / 30);

    if (dt <= 0) return;

    world.step(dt);
    positionsChanged.value++;

    if (!world.needsFrames) {
      _sleeping = true;
      synchronizeTicker();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      Localizations.localeOf(context);
      synchronize(Size(constraints.maxWidth, constraints.maxHeight));
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
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
                    gradient: const RadialGradient(
                      center: Alignment(-.3, -.3),
                      colors: [Color(0xB3FFFFFF), Color(0x59D6EEC7)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .65),
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

  Widget bubble(BubbleBody body, Subscription sub) => Positioned(
    key: ValueKey('bubble-${body.id}'),
    left: 0,
    top: 0,
    width: body.radius * 2,
    height: body.radius * 2,
    child: AnimatedBuilder(
      animation: positionsChanged,
      child: RepaintBoundary(child: bubbleContent(body, sub)),
      builder: (context, child) => Transform.translate(
        offset: body.position - Offset(body.radius, body.radius),
        child: child,
      ),
    ),
  );

  Widget bubbleContent(BubbleBody body, Subscription sub) => Semantics(
    button: true,
    label: '${sub.terms.name}, ${original(sub.terms)}',
    child: GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      onTap: () => widget.onTap(body.id),
      onPanStart: (event) {
        body.held = true;
        body.velocity = Offset.zero;
        dragTime = event.sourceTimeStamp;
        wakePhysics();
        setState(() {});
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
        body.position = world.contain(body.position + event.delta, body.radius);
        body.velocity = BubblePhysics.limit(event.delta / dt);
        positionsChanged.value++;
      },
      onPanEnd: (event) {
        body.held = false;
        dragTime = null;
        final fling = event.velocity.pixelsPerSecond;
        body.velocity = BubblePhysics.limit(
          fling.distance > 30 ? fling * .6375 : body.velocity * .15,
        );
        wakePhysics();
        setState(() {});
      },
      onPanCancel: () {
        body.held = false;
        dragTime = null;
        wakePhysics();
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-.4, -.5),
            radius: 1.3,
            colors: [
              Color(0xF2FFFFFF),
              Color(0xC7FFFFFF),
              Color(0x8CE6F0E6),
              Color(0xBFFFFFFF),
            ],
            stops: [0, .4, .8, 1],
          ),
          border: Border.all(
            color: body.held ? mint : const Color(0xD9FFFFFF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ink.withValues(alpha: body.held ? .18 : .1),
              blurRadius: body.held ? 30 : 24,
              spreadRadius: -6,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: body.radius * .18,
              left: body.radius * .36,
              width: body.radius * .88,
              height: body.radius * .44,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -.44,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                      gradient: RadialGradient(
                        radius: .8,
                        colors: [Color(0xD9FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: body.radius * 2 - 18,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ServiceGlyph(sub.terms.icon, size: body.radius * .62),
                        const SizedBox(height: 6),
                        FittedBox(
                          child: Text(
                            original(sub.terms),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.25,
                              color: ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sub.terms.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.15,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
