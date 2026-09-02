import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../../core/widgets/instagram_widgets.dart';
import '../../../analysis/presentation/analysis_provider.dart';
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
        title: GradientText(
          '\uAC10\uB3C4',
          style: AppTypography.wordmark.copyWith(fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 26),
            tooltip: '\uC0C8 \uBD84\uC11D',
            onPressed: () => context.push(AppRoutes.photoUpload),
          ),
          const SizedBox(width: 4),
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentAnalysesProvider);
                // 스트림이 새 데이터를 방출할 때까지 대기
                await ref.read(recentAnalysesProvider.future);
              },
              child: analysesAsync.when(
                data: (analyses) {
                  if (analyses.isEmpty) return _EmptyFeed();
                  return _AnalysisFeed(analyses: analyses);
                },
                loading: () => LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                      ),
                    );
                  },
                ),
                error: (e, st) {
                  final message = e is ApiException
                      ? e.userMessage
                      : '\uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4';
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(child: Text(message)),
                        ),
                      );
                    },
                  );
                },
              ),
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
                      : 'Instagram \uC5F0\uACB0\uB428',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasStyleProfile
                      ? '\uC2A4\uD0C0\uC77C \uD504\uB85C\uD544 \uC801\uC6A9 \uC911'
                      : '\uC2A4\uD0C0\uC77C \uD504\uB85C\uD544 \uBD84\uC11D \uAC00\uB2A5',
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
              '\uC5F0\uACB0\uB428',
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
                color: context.instaSecondary,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InstagramGradientAvatar(
                    size: 96,
                    borderWidth: 3,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 36,
                      color: context.instaSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '\uC544\uC9C1 \uBD84\uC11D\uD55C \uC0AC\uC9C4\uC774 \uC5C6\uC2B5\uB2C8\uB2E4',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\uC0AC\uC9C4\uC744 \uC5C5\uB85C\uB4DC\uD558\uACE0 AI \uAC10\uAC01 \uCF54\uCE6D\uC744 \uBC1B\uC544\uBCF4\uC138\uC694',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.instaSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 사용법 가이드
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        _GuideStep(
                          number: '1',
                          text: '\uC0AC\uC9C4\uC744 \uC120\uD0DD\uD558\uAC70\uB098 \uCE74\uBA54\uB77C\uB85C \uCB2C\uC73C\uC138\uC694',
                        ),
                        const SizedBox(height: 8),
                        _GuideStep(
                          number: '2',
                          text: 'AI\uAC00 \uC0C9\uAC10\u00B7\uAD6C\uB3C4\u00B7\uD1A4\uC744 \uBD84\uC11D\uD569\uB2C8\uB2E4',
                        ),
                        const SizedBox(height: 8),
                        _GuideStep(
                          number: '3',
                          text: '\uB9DE\uCDA4 \uBCC0\uD615 \uACB0\uACFC\uB97C \uD655\uC778\uD558\uACE0 \uC800\uC7A5\uD558\uC138\uC694',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: InstagramGradientButton(
                      height: 44,
                      onPressed: () => context.push(AppRoutes.photoUpload),
                      child: const Text(
                        '\uCCAB \uC0AC\uC9C4 \uBD84\uC11D\uD558\uAE30',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String text;
  const _GuideStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: context.instaSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisFeed extends StatelessWidget {
  final List<dynamic> analyses;
  const _AnalysisFeed({required this.analyses});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
                      backgroundColor: context.instaDivider,
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
                        style: AppTypography.username,
                      ),
                      Text(
                        _formatDate(record.createdAt),
                        style: AppTypography.meta
                            .copyWith(color: context.instaSecondary),
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
                    '${record.overallScore}\uC810',
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
            child: _buildImage(context, record.imagePath),
          ),
          // 액션 바 — 인스타그램 게시물의 아이콘 행
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
            child: Row(
              children: [
                _FeedAction(
                  icon: Icons.auto_fix_high_outlined,
                  tooltip: '\uC0AC\uC9C4 \uBCC0\uD615',
                  onTap: () => context.push(
                    AppRoutes.transform,
                    extra: {
                      'imagePath': record.imagePath,
                      'analysisJson': record.analysisJson,
                    },
                  ),
                ),
                _FeedAction(
                  icon: Icons.ios_share_outlined,
                  tooltip: '\uACF5\uC720',
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text: '\uD83D\uDCF8 \uAC10\uB3C4 \uBD84\uC11D \uACB0\uACFC\n'
                          '\uC2A4\uD0C0\uC77C: ${record.styleCategory}\n'
                          '\uC810\uC218: ${record.overallScore}\uC810\n\n'
                          '#\uAC10\uB3C4 #\uC0AC\uC9C4\uBD84\uC11D #AI\uCF54\uCE6D',
                    ),
                  ),
                ),
                const Spacer(),
                _TempChip(temperature: record.colorTemperature),
              ],
            ),
          ),
          // \uCEA1\uC158 — \uC778\uC2A4\uD0C0\uADF8\uB7A8 \uAC8C\uC2DC\uBB3C\uC758 \uBCF8\uBB38 \uC904
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTypography.caption
                    .copyWith(color: context.instaPrimaryText),
                children: [
                  TextSpan(
                    text: record.styleCategory,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '  \uAC10\uB3C4 ${record.overallScore}\uC810\uC73C\uB85C \uC77D\uD614\uC5B4\uC694',
                    style: TextStyle(color: context.instaSecondary),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              _formatDate(record.createdAt),
              style:
                  AppTypography.meta.copyWith(color: context.instaSecondary),
            ),
          ),
          const InstaHairline(),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: context.instaDivider,
      child: Center(
        child: Icon(Icons.image, size: 40, color: context.instaSecondary),
      ),
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
      'warm' => (AppColors.warmColor, '\uB530\uB73B\uD55C'),
      'cool' => (AppColors.coolColor, '\uCC28\uAC00\uC6B4'),
      _ => (AppColors.neutralColor, '\uC911\uC131'),
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

/// 피드 카드 하단의 인스타그램식 액션 아이콘.
class _FeedAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _FeedAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 24),
      color: context.instaPrimaryText,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      onPressed: onTap,
    );
  }
}
