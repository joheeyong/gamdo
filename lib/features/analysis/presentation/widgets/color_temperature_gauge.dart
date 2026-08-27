import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';

class ColorTemperatureGauge extends StatelessWidget {
  final String temperature;

  const ColorTemperatureGauge({
    super.key,
    required this.temperature,
  });

  double get _position {
    switch (temperature) {
      case 'warm':
        return 0.8;
      case 'cool':
        return 0.2;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.colorTemperature,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Gradient bar
            Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.coolColor,
                        AppColors.neutralColor,
                        AppColors.warmColor,
                      ],
                    ),
                  ),
                ),
                // Indicator
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final indicatorX =
                          constraints.maxWidth * _position - 12;
                      return Stack(
                        children: [
                          Positioned(
                            left: indicatorX.clamp(
                                0, constraints.maxWidth - 24),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '차가운',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.coolColor,
                  ),
                ),
                Text(
                  '중성',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutralColor,
                  ),
                ),
                Text(
                  '따뜻한',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.warmColor,
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
