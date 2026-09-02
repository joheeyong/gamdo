import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../../core/widgets/instagram_widgets.dart';
import '../providers/history_provider.dart';

/// 분석 기록 화면.
///
/// 인스타그램 프로필의 사진 그리드와 같은 구조 — 3열 정사각 타일에
/// 1px 간격, 탭하면 상세, 길게 누르면 액션 시트.
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

  static const _sortLabels = {
    HistorySortOrder.newest: '최신순',
    HistorySortOrder.scoreHigh: '점수 높은순',
    HistorySortOrder.scoreLow: '점수 낮은순',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(filteredAnalysesProvider);
    final selectedFilter = ref.watch(selectedStyleFilterProvider);
    final sortOrder = ref.watch(selectedSortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.history),
        actions: [
          // 정렬: 인스타그램은 팝업 메뉴 대신 하단 시트를 쓴다
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: '정렬',
            onPressed: () => _showSortSheet(context, ref, sortOrder),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 스타일 필터 알약
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _styleFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _styleFilters[index];
                return InstaPill(
                  label: filter ?? context.l10n.allStyles,
                  selected: selectedFilter == filter,
                  onTap: () => ref
                      .read(selectedStyleFilterProvider.notifier)
                      .state = filter,
                );
              },
            ),
          ),
          const InstaHairline(),

          Expanded(
            child: analysesAsync.when(
              data: (analyses) {
                if (analyses.isEmpty) {
                  return _EmptyGrid(hasFilter: selectedFilter != null);
                }
                return Column(
                  children: [
                    _GridSummary(
                      count: analyses.length,
                      sortLabel: _sortLabels[sortOrder]!,
                      averageScore: analyses.isEmpty
                          ? 0
                          : (analyses
                                      .map((a) => a.overallScore)
                                      .reduce((a, b) => a + b) /
                                  analyses.length)
                              .round(),
                    ),
                    Expanded(
                      child: _PhotoGrid(
                        analyses: analyses,
                        onLongPress: (record) =>
                            _showItemSheet(context, ref, record),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.instaSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(
    BuildContext context,
    WidgetRef ref,
    HistorySortOrder current,
  ) {
    showInstaSheet(
      context,
      title: '정렬',
      actions: [
        for (final entry in _sortLabels.entries)
          InstaSheetAction(
            icon: switch (entry.key) {
              HistorySortOrder.newest => Icons.access_time,
              HistorySortOrder.scoreHigh => Icons.arrow_upward,
              HistorySortOrder.scoreLow => Icons.arrow_downward,
            },
            label: entry.key == current ? '${entry.value}  ✓' : entry.value,
            onTap: () => ref
                .read(selectedSortOrderProvider.notifier)
                .state = entry.key,
          ),
      ],
    );
  }

  void _showItemSheet(
    BuildContext context,
    WidgetRef ref,
    AnalysisRecord record,
  ) {
    showInstaSheet(
      context,
      actions: [
        InstaSheetAction(
          icon: Icons.insights_outlined,
          label: '분석 결과 보기',
          onTap: () => context.push(
            AppRoutes.analysisResult,
            extra: {
              'analysisId': record.id,
              'analysisJson': record.analysisJson,
              'imagePath': record.imagePath,
            },
          ),
        ),
        InstaSheetAction(
          icon: Icons.auto_fix_high_outlined,
          label: '사진 변형하기',
          onTap: () => context.push(
            AppRoutes.transform,
            extra: {
              'imagePath': record.imagePath,
              'analysisJson': record.analysisJson,
            },
          ),
        ),
        InstaSheetAction(
          icon: Icons.delete_outline,
          label: context.l10n.delete,
          isDestructive: true,
          onTap: () => _confirmDelete(context, ref, record),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AnalysisRecord record,
  ) async {
    final confirmed = await showInstaConfirm(
      context,
      title: context.l10n.deleteAnalysis,
      message: context.l10n.deleteConfirm,
      confirmLabel: context.l10n.delete,
      cancelLabel: context.l10n.cancel,
      isDestructive: true,
    );
    if (!confirmed) return;

    await ref.read(historyRepositoryProvider).delete(record.id);
    if (context.mounted) {
      showInstaToast(context, '기록이 삭제되었습니다', icon: Icons.check_circle_outline);
    }
  }
}

// ── 그리드 요약 줄 ──

class _GridSummary extends StatelessWidget {
  final int count;
  final int averageScore;
  final String sortLabel;

  const _GridSummary({
    required this.count,
    required this.averageScore,
    required this.sortLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Text(
            '사진 $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.instaPrimaryText,
            ),
          ),
          Text(
            '  ·  평균 $averageScore점',
            style: TextStyle(fontSize: 13, color: context.instaSecondary),
          ),
          const Spacer(),
          Text(
            sortLabel,
            style: TextStyle(fontSize: 12, color: context.instaSecondary),
          ),
        ],
      ),
    );
  }
}

// ── 사진 그리드 ──

class _PhotoGrid extends StatelessWidget {
  final List<AnalysisRecord> analyses;
  final void Function(AnalysisRecord) onLongPress;

  const _PhotoGrid({required this.analyses, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        // 인스타그램 그리드는 타일 사이가 1.5px로 거의 붙어 있다
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
      ),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final record = analyses[index];
        return _GridTile(
          record: record,
          onLongPress: () => onLongPress(record),
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  final AnalysisRecord record;
  final VoidCallback onLongPress;

  const _GridTile({required this.record, required this.onLongPress});

  Color get _scoreColor {
    if (record.overallScore >= 80) return AppColors.scoreExcellent;
    if (record.overallScore >= 60) return AppColors.scoreGood;
    if (record.overallScore >= 40) return AppColors.scoreAverage;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.analysisResult,
        extra: {
          'analysisId': record.id,
          'analysisJson': record.analysisJson,
          'imagePath': record.imagePath,
        },
      ),
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _thumbnail(context),
          // 점수 배지 — 인스타그램의 '여러 장' 표식 자리
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _scoreColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${record.overallScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(BuildContext context) {
    final file = File(record.thumbnailPath ?? record.imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, cacheWidth: 400);
    }
    return Container(
      color: context.instaDivider,
      child: Icon(Icons.image_outlined, color: context.instaSecondary),
    );
  }
}

// ── 빈 상태 ──

class _EmptyGrid extends StatelessWidget {
  final bool hasFilter;

  const _EmptyGrid({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InstagramGradientAvatar(
              size: 88,
              borderWidth: 2,
              child: Icon(
                Icons.grid_on_outlined,
                size: 32,
                color: context.instaSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? '이 스타일의 기록이 없습니다' : context.l10n.noAnalysisYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.instaPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? '다른 스타일을 선택해 보세요'
                  : '사진을 분석하면 여기에 차곡차곡 쌓여요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.instaSecondary),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: InstagramGradientButton(
                  height: 40,
                  onPressed: () => context.push(AppRoutes.photoUpload),
                  child: const Text(
                    '사진 분석하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
