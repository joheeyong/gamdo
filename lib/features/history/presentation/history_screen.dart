import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/score_indicator.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _styleFilters = [
    null, // All
    '미니멀',
    '빈티지',
    '모던',
    '내추럴',
    '드라마틱',
    '파스텔',
    '다크',
    '필름',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(filteredAnalysesProvider);
    final selectedFilter = ref.watch(selectedStyleFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.history),
      ),
      body: Column(
        children: [
          // Style filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _styleFilters.length,
              itemBuilder: (context, index) {
                final filter = _styleFilters[index];
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter ?? context.l10n.allStyles),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(selectedStyleFilterProvider.notifier)
                          .state = filter;
                    },
                    selectedColor:
                        context.colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: context.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Analysis list
          Expanded(
            child: analysesAsync.when(
              data: (analyses) {
                if (analyses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 64,
                          color: context.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.noAnalysisYet,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: analyses.length,
                  itemBuilder: (context, index) {
                    return _HistoryItem(
                      record: analyses[index],
                      onDelete: () async {
                        final db = ref.read(appDatabaseProvider);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(context.l10n.deleteAnalysis),
                            content: Text(context.l10n.deleteConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(context.l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  context.l10n.delete,
                                  style:
                                      const TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await db.deleteAnalysis(analyses[index].id);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final AnalysisRecord record;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('analysis_${record.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(
              AppRoutes.analysisResult,
              extra: {
                'analysisId': record.id,
                'analysisJson': record.analysisJson,
                'imagePath': record.imagePath,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _buildThumbnail(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.styleCategory,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(record.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                ScoreIndicator(score: record.overallScore, size: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final file = File(record.imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.dividerLight,
      child: const Icon(Icons.image, color: AppColors.textSecondaryLight),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
