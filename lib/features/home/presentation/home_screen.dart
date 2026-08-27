import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/score_indicator.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(recentAnalysesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '감',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.appTitle,
              style: context.textTheme.headlineSmall,
            ),
          ],
        ),
      ),
      body: analysesAsync.when(
        data: (analyses) {
          if (analyses.isEmpty) {
            return _EmptyState(context: context);
          }
          return _AnalysisList(analyses: analyses);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.photoUpload),
        icon: const Icon(Icons.camera_alt),
        label: Text(context.l10n.analyze),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final BuildContext context;

  const _EmptyState({required this.context});

  @override
  Widget build(BuildContext innerContext) {
    final ctx = context;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 80,
              color: ctx.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              ctx.l10n.noAnalysisYet,
              style: ctx.textTheme.headlineSmall?.copyWith(
                color: ctx.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ctx.l10n.startFirstAnalysis,
              style: ctx.textTheme.bodyMedium?.copyWith(
                color: ctx.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisList extends StatelessWidget {
  final List<dynamic> analyses;

  const _AnalysisList({required this.analyses});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final record = analyses[index];
        return _AnalysisCard(record: record);
      },
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final dynamic record;

  const _AnalysisCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
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
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _buildThumbnail(record.imagePath),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.styleCategory,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TemperatureChip(temperature: record.colorTemperature),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(record.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Score
              ScoreIndicator(score: record.overallScore, size: 52),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String path) {
    final file = File(path);
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

class _TemperatureChip extends StatelessWidget {
  final String temperature;

  const _TemperatureChip({required this.temperature});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;

    switch (temperature) {
      case 'warm':
        chipColor = AppColors.warmColor;
        label = '따뜻한';
      case 'cool':
        chipColor = AppColors.coolColor;
        label = '차가운';
      default:
        chipColor = AppColors.neutralColor;
        label = '중성';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: chipColor,
        ),
      ),
    );
  }
}
