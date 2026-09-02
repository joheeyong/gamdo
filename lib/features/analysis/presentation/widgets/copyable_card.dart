import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/insta_ui.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A card displaying hashtags with a "copy all" button.
class HashtagCard extends StatelessWidget {
  final String title;
  final List<String> hashtags;
  final IconData icon;
  final Color color;

  const HashtagCard({
    super.key,
    required this.title,
    required this.hashtags,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final allTags = hashtags.join(' ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _CopyButton(
                  text: allTags,
                  color: color,
                  label: '전체 복사',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hashtags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small copy icon button that copies text and shows a snackbar.
class _CopyButton extends StatelessWidget {
  final String text;
  final Color color;
  final String? label;

  const _CopyButton({
    required this.text,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        showInstaToast(context, '복사되었습니다', icon: Icons.check);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 14, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
