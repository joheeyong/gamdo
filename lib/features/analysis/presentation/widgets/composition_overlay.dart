import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';

class CompositionOverlay extends StatefulWidget {
  final String imagePath;
  final String technique;
  final double balanceScore;

  const CompositionOverlay({
    super.key,
    required this.imagePath,
    required this.technique,
    required this.balanceScore,
  });

  @override
  State<CompositionOverlay> createState() => _CompositionOverlayState();
}

class _CompositionOverlayState extends State<CompositionOverlay> {
  bool _showGrid = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.grid_on,
                          size: 18, color: context.colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.technique,
                          style: context.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '그리드',
                      style: context.textTheme.bodySmall,
                    ),
                    Switch(
                      value: _showGrid,
                      onChanged: (v) => setState(() => _showGrid = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Image with grid overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                    ),
                    if (_showGrid) const _GridOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Balance score
            Row(
              children: [
                Text(
                  context.l10n.balance,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: widget.balanceScore,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(widget.balanceScore * 100).toInt()}%',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Vertical lines (rule of thirds)
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );

    // Intersection dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final intersections = [
      Offset(size.width / 3, size.height / 3),
      Offset(size.width * 2 / 3, size.height / 3),
      Offset(size.width / 3, size.height * 2 / 3),
      Offset(size.width * 2 / 3, size.height * 2 / 3),
    ];

    for (final point in intersections) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
