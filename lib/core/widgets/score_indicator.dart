import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScoreIndicator extends StatelessWidget {
  final int score;
  final double size;

  const ScoreIndicator({
    super.key,
    required this.score,
    this.size = 80,
  });

  Color get _scoreColor {
    if (score >= 80) return AppColors.scoreExcellent;
    if (score >= 60) return AppColors.scoreGood;
    if (score >= 40) return AppColors.scoreAverage;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 6,
              backgroundColor: _scoreColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w700,
                  color: _scoreColor,
                ),
              ),
              Text(
                '점',
                style: TextStyle(
                  fontSize: size * 0.14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
