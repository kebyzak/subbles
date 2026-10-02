import 'package:flutter/material.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';

class ServiceGlyph extends StatelessWidget {
  final String value;
  final double size;
  final Color color;

  const ServiceGlyph(
    this.value, {
    super.key,
    this.size = 22,
    this.color = accent,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = switch (value) {
      '🎵' => Icons.music_note_rounded,
      '📺' => Icons.tv_rounded,
      '☁️' => Icons.cloud_rounded,
      '🤖' => Icons.smart_toy_outlined,
      '💡' => Icons.lightbulb_outline_rounded,
      '📚' => Icons.menu_book_rounded,
      '✨' => Icons.auto_awesome_rounded,
      '💼' => Icons.work_outline_rounded,
      '🎮' => Icons.sports_esports_rounded,
      '🌐' => Icons.language_rounded,
      '🏋️' => Icons.fitness_center_rounded,
      '📱' => Icons.smartphone_rounded,
      _ => null,
    };

    return glyph == null
        ? Text(
            value,
            style: TextStyle(fontSize: size, fontFamilyFallback: emojiFonts),
          )
        : Icon(glyph, size: size, color: color);
  }
}

class ServiceIcon extends StatelessWidget {
  final String icon;
  final double size;

  const ServiceIcon(this.icon, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: bubbleSurfaceDecoration(
      radius: size * .32,
      color: mint,
      shadow: false,
    ),
    alignment: Alignment.center,
    child: ServiceGlyph(icon, size: size * .5),
  );
}
