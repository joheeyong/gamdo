import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/instagram_widgets.dart';
import '../../analysis/presentation/analysis_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(recentAnalysesProvider);
    final instagramAuth = ref.watch(instagramAuthProvider);
    final pipelineState = ref.watch(styleAnalysisPipelineProvider);
    final hasStyleProfile = ref.watch(userStyleProfileProvider) != null;

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
      body: Column(
        children: [
          // 분석 진행 상태 배너
          if (pipelineState.status != StyleAnalysisStatus.idle)
            _AnalysisBanner(state: pipelineState),
          if (instagramAuth.isConnected)
            _InstagramProfileCard(
              auth: instagramAuth,
              hasStyleProfile: hasStyleProfile,
            ),
          Expanded(
            child: analysesAsync.when(
              data: (analyses) {
                if (analyses.isEmpty) return _EmptyFeed();
                return _AnalysisFeed(analyses: analyses);
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              error: (e, st) {
                return Center(child: Text('오류: $e'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InstagramProfileCard extends StatelessWidget {
  final InstagramAuth auth;
  final bool hasStyleProfile;
  const _InstagramProfileCard({
    required this.auth,
    this.hasStyleProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          InstagramGradientAvatar(
            size: 40,
            child: const Icon(
              Icons.camera_alt,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.username != null
                      ? '@${auth.username}'
                      : 'Instagram 연결됨',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasStyleProfile
                      ? '스타일 프로필 적용 중'
                      : '스타일 프로필 분석 가능',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasStyleProfile
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.instagramGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '연결됨',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisBanner extends ConsumerStatefulWidget {
  final StyleAnalysisState state;
  const _AnalysisBanner({required this.state});

  @override
  ConsumerState<_AnalysisBanner> createState() => _AnalysisBannerState();
}

class _AnalysisBannerState extends ConsumerState<_AnalysisBanner> {
  bool _dismissed = false;

  @override
  void didUpdateWidget(covariant _AnalysisBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.status == StyleAnalysisStatus.completed &&
        oldWidget.state.status != StyleAnalysisStatus.completed) {
      _dismissed = false;
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          ref.read(styleAnalysisPipelineProvider.notifier).reset();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final isError = widget.state.status == StyleAnalysisStatus.error;
    final isCompleted = widget.state.status == StyleAnalysisStatus.completed;
    final isInProgress = !isError && !isCompleted;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.1)
            : isCompleted
                ? Colors.green.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.3)
              : isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          if (isInProgress)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              isCompleted ? Icons.check_circle : Icons.error_outline,
              size: 18,
              color: isCompleted ? Colors.green : AppColors.error,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.state.statusMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isError ? AppColors.error : null,
              ),
            ),
          ),
          if (isError || isCompleted)
            GestureDetector(
              onTap: () {
                setState(() => _dismissed = true);
                ref.read(styleAnalysisPipelineProvider.notifier).reset();
              },
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
            ),
        ],
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
          InstagramGradientAvatar(
            size: 96,
            borderWidth: 3,
            child: Icon(
              Icons.camera_alt_outlined,
              size: 36,
              color: AppColors.textSecondaryLight,
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
            child: InstagramGradientButton(
              height: 44,
              onPressed: () => context.push(AppRoutes.photoUpload),
              child: const Text(
                '첫 사진 분석하기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                InstagramGradientAvatar(
                  size: 36,
                  child: Padding(
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
                Expanded(
                  child: Text(
                    '${record.styleCategory} · ${record.overallScore}점',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
