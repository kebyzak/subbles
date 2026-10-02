import 'dart:math' as math;
import 'dart:ui';

class BubbleBody {
  final String id;
  final double radius;
  Offset position, velocity;
  bool held = false;

  BubbleBody(this.id, this.radius, this.position, this.velocity);

  double get inverseMass => held ? 0 : 1 / (radius * radius);
}

class BubblePhysics {
  final List<BubbleBody> bodies;
  final Size size;

  BubblePhysics(this.bodies, this.size);

  Offset contain(Offset position, double radius) => Offset(
    position.dx.clamp(radius, math.max(radius, size.width - radius)),
    position.dy.clamp(radius, math.max(radius, size.height - radius)),
  );

  bool get needsFrames =>
      bodies.any((body) => body.held || body.velocity.distanceSquared >= 1);

  static Offset limit(Offset velocity, [double maximum = 900]) =>
      velocity.distanceSquared > maximum * maximum
      ? velocity / velocity.distance * maximum
      : velocity;

  void step(double elapsed) {
    final seconds = elapsed.clamp(0.0, 1 / 30);
    if (seconds <= 0) return;
    final count = math.max(1, (seconds * 120).ceil());
    final dt = seconds / count;
    final damping = math.exp(-1.5 * dt);
    for (var substep = 0; substep < count; substep++) {
      for (final body in bodies) {
        if (body.held) continue;
        body.velocity = limit(body.velocity) * damping;
        if (body.velocity.distanceSquared < 1) {
          body.velocity = Offset.zero;
        }
        final next = body.position + body.velocity * dt;
        final bounded = contain(next, body.radius);
        if (next.dx != bounded.dx) {
          body.velocity = Offset(-body.velocity.dx * .645, body.velocity.dy);
        }
        if (next.dy != bounded.dy) {
          body.velocity = Offset(body.velocity.dx, -body.velocity.dy * .645);
        }
        body.position = bounded;
      }
      for (var pass = 0; pass < 3; pass++) {
        for (var i = 0; i < bodies.length; i++) {
          for (var j = i + 1; j < bodies.length; j++) {
            final a = bodies[i], b = bodies[j];
            final inverseMass = a.inverseMass + b.inverseMass;
            if (inverseMass == 0) continue;
            final delta = b.position - a.position;
            final minimumDistance = a.radius + b.radius + 2;
            final distanceSquared = delta.distanceSquared;
            if (distanceSquared >= minimumDistance * minimumDistance) continue;
            final distance = math.sqrt(distanceSquared);
            final overlap = minimumDistance - distance;
            final normal = distance < .001
                ? const Offset(1, 0)
                : delta / distance;
            a.position = contain(
              a.position - normal * overlap * a.inverseMass / inverseMass,
              a.radius,
            );
            b.position = contain(
              b.position + normal * overlap * b.inverseMass / inverseMass,
              b.radius,
            );
            final relative = b.velocity - a.velocity;
            final approaching =
                relative.dx * normal.dx + relative.dy * normal.dy;
            if (approaching < 0) {
              final impulse = -(1 + .645) * approaching / inverseMass;
              a.velocity -= normal * impulse * a.inverseMass;
              b.velocity += normal * impulse * b.inverseMass;
            }
          }
        }
      }
    }
  }
}
