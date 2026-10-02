import 'package:flutter/material.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';

class Panel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: bubbleSurfaceDecoration(color: color),
    child: child,
  );
}
