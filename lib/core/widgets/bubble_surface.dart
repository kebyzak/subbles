import 'package:flutter/material.dart';
import 'package:subbles/core/theme/colors.dart';

BoxDecoration bubbleSurfaceDecoration({
  double radius = 24,
  Color? color,
  bool shadow = true,
}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: color == null
        ? const [Color(0xEFFFFFFF), Color(0xA6FFFFFF)]
        : [color, Color.lerp(color, Colors.white, .06)!],
  ),
  border: Border.all(
    color: Colors.white.withValues(alpha: color == ink ? .18 : .8),
  ),
  boxShadow: shadow
      ? const [
          BoxShadow(
            color: Color(0x1020362F),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
        ]
      : const [],
);

class BubbleBackdrop extends StatelessWidget {
  const BubbleBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _AmbientPainter(), child: SizedBox.expand()),
    ),
  );
}

class BubbleSheetSurface extends StatelessWidget {
  final Widget child;

  const BubbleSheetSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF5FFFFFF), Color(0xF0F3F6F0), Color(0xEBE8F2E1)],
        stops: [0, .55, 1],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .85)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2420362F),
          blurRadius: 28,
          offset: Offset(0, -6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SafeArea(top: false, child: child),
    ),
  );
}

class BubbleSheetHandle extends StatelessWidget {
  const BubbleSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 38,
      height: 5,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(100),
      ),
    ),
  );
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bubbleCanvas);

    for (final glow in const [
      (Offset(.15, .08), .65, Color(0x99D6EEC7)),
      (Offset(1.02, .37), .72, Color(0x26416E4D)),
      (Offset(.04, .72), .62, Color(0x8CD6EEC7)),
      (Offset(.76, .94), .55, Color(0x3382B591)),
    ]) {
      final center = Offset(size.width * glow.$1.dx, size.height * glow.$1.dy);
      final radius = size.width * glow.$2;
      final bounds = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [glow.$3, glow.$3.withValues(alpha: 0)],
          stops: const [0, 1],
        ).createShader(bounds);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) => false;
}
