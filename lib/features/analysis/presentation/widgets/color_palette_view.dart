import 'package:flutter/material.dart';
import '../../../../core/extensions/color_extensions.dart';
import '../../../../core/extensions/context_extensions.dart';

class ColorPaletteView extends StatelessWidget {
  final List<String> colors;
  final String description;

  const ColorPaletteView({
    super.key,
    required this.colors,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.dominantColors,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Color swatches
            Row(
              children: colors.map((hex) {
                final color = hex.toColor();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hex.toUpperCase(),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
