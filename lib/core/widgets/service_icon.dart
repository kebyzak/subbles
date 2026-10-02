import 'package:flutter/material.dart';
import 'package:subbles/core/theme/colors.dart';

class ServiceIcon extends StatelessWidget {
  final String icon;
  final double size;

  const ServiceIcon(this.icon, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: paper,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    alignment: Alignment.center,
    child: Text(
      icon,
      style: TextStyle(fontSize: size * .5, fontFamilyFallback: emojiFonts),
    ),
  );
}
