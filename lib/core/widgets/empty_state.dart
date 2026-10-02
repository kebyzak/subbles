import 'package:flutter/material.dart';
import 'package:subbles/core/theme/colors.dart';

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
        Icon(icon, size: 38, color: accent),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.5),
        ),
      ],
    ),
  );
}