import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(recentAnalysesProvider);

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.instagramGradient.createShader(bounds),
          child: const Text(
            '감도',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => context.push(AppRoutes.photoUpload),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: analysesAsync.when(
        data: (analyses) {
          if (analyses.isEmpty) return _EmptyFeed();
          return _AnalysisFeed(analyses: analyses);
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
        error: (e, st) {
          print('[Home] DB error: $e\n$st');
          return Center(child: Text('오류: $e'));
        },
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Instagram story-style ring
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.storyGradient,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 36,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '아직 분석한 사진이 없습니다',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '사진을 업로드하고 AI 감각 코칭을 받아보세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.instagramGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.photoUpload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text(
                  '첫 사진 분석하기',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisFeed extends StatelessWidget {
  final List<dynamic> analyses;
  const _AnalysisFeed({required this.analyses});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final record = analyses[index];
        return _FeedCard(record: record);
      },
    );
  }
}

/// Instagram feed-style card
class _FeedCard extends StatelessWidget {
  final dynamic record;
  const _FeedCard({required this.record});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Story-ring style avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.storyGradient,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.dividerLight,
                      child: Text(
                        record.styleCategory.isNotEmpty ? record.styleCategory[0] : '?',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.styleCategory,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatDate(record.createdAt),
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.instagramGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${record.overallScore}점',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Image (full-width, Instagram style)
          AspectRatio(
            aspectRatio: 1,
            child: _buildImage(record.imagePath),
          ),
          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _TempChip(temperature: record.colorTemperature),
                const SizedBox(width: 8),
                Text(
                  '${record.styleCategory} · ${record.overallScore}점',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.textSecondaryLight, size: 20),
              ],
            ),
          ),
          Divider(height: 0.5),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.dividerLight,
      child: const Center(child: Icon(Icons.image, size: 40, color: AppColors.textSecondaryLight)),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _TempChip extends StatelessWidget {
  final String temperature;
  const _TempChip({required this.temperature});

  @override
  Widget build(BuildContext context) {
    final (Color c, String l) = switch (temperature) {
      'warm' => (AppColors.warmColor, '따뜻한'),
      'cool' => (AppColors.coolColor, '차가운'),
      _ => (AppColors.neutralColor, '중성'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
    );
  }
}
