import 'package:flutter/material.dart';
import 'package:subbles/core/localization/app_text.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.layers_outlined,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    child: Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: bubbleSurfaceDecoration(
            radius: 100,
            color: mint,
            shadow: false,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 32, color: accent),
        ),
        const SizedBox(height: 16),
        AppText(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        AppText(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.5),
        ),
      ],
    ),
  );
}
