import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/photo_analysis.dart';

class ToneReportCard extends StatelessWidget {
  final ToneReport toneReport;

  const ToneReportCard({super.key, required this.toneReport});

  /// 보여 줄 내용이 하나라도 있는지. 없으면 카드를 그리지 않는다.
  static bool hasContent(ToneReport r) =>
      displayableAnalysisText(r.styleCategory) != null ||
      displayableAnalysisText(r.overallMood) != null ||
      displayableAnalysisText(r.narrative) != null;

  @override
  Widget build(BuildContext context) {
    final style = displayableAnalysisText(toneReport.styleCategory);
    final mood = displayableAnalysisText(toneReport.overallMood);
    final narrative = displayableAnalysisText(toneReport.narrative);
    if (style == null && mood == null && narrative == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (style != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      style,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (mood != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondary.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mood,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (narrative != null) ...[
              if (style != null || mood != null) const SizedBox(height: 16),
              Text(
                narrative,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
