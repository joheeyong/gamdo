import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/color_extensions.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../analysis/presentation/analysis_provider.dart';
import '../providers/home_provider.dart';

/// 홈 — 벤토 그리드.
///
/// 회백색 바탕 위에 크기가 다른 카드를 짜 맞춘다.
/// 맨 위 큰 카드는 최근 보정한 사진, 그 아래 라임 카드는 분석한 사진 수,
/// 흰 카드는 내 감도(스타일 프로필), 먹색 카드는 새 분석 버튼이다.
/// 그 아래로 지난 기록을 둥근 사진 타일 두 열로 보여 준다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _gap = 10;
  static const EdgeInsets _pagePadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(recentAnalysesProvider);
    final instagramAuth = ref.watch(instagramAuthProvider);
    final pipelineState = ref.watch(styleAnalysisPipelineProvider);
    final styleProfile = ref.watch(userStyleProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '감도',
          style: AppTypography.wordmark.copyWith(
            fontSize: 26,
            color: context.instaPrimaryText,
          ),
        ),
        actions: [
          if (instagramAuth.isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _ConnectedPill(username: instagramAuth.username),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentAnalysesProvider);
          // 스트림이 새 데이터를 방출할 때까지 대기
          await ref.read(recentAnalysesProvider.future);
        },
        child: analysesAsync.when(
          data: (analyses) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              if (pipelineState.status != StyleAnalysisStatus.idle)
                _AnalysisBanner(state: pipelineState),
              Padding(
                padding: _pagePadding,
                child: _BentoGrid(
                  analyses: analyses,
                  styleProfile: styleProfile,
                ),
              ),
              if (analyses.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    '지난 기록',
                    style: AppTypography.sectionTitle
                        .copyWith(color: context.instaPrimaryText),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _RecordGrid(records: analyses.skip(1).toList()),
                ),
              ],
            ],
          ),
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
                : '오류가 발생했습니다';
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
    );
  }
}

/// 상단 바 오른쪽의 '인스타그램 연결됨' 알약.
class _ConnectedPill extends StatelessWidget {
  final String? username;
  const _ConnectedPill({this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.instaSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            username != null ? '@$username' : 'Instagram',
            style: AppTypography.badge.copyWith(color: context.instaPrimaryText),
          ),
        ],
      ),
    );
  }
}

/// 벤토 카드 하나의 공통 껍데기.
class _BentoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _BentoCard({
    required this.child,
    this.color,
    this.height,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.instaSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

class _BentoGrid extends StatelessWidget {
  final List<AnalysisRecord> analyses;
  final Map<String, dynamic>? styleProfile;

  const _BentoGrid({required this.analyses, required this.styleProfile});

  @override
  Widget build(BuildContext context) {
    const gap = HomeScreen._gap;
    final latest = analyses.isEmpty ? null : analyses.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        latest == null ? const _EmptyHeroCard() : _LatestCard(record: latest),
        const SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _CountCard(count: analyses.length)),
              const SizedBox(width: gap),
              Expanded(child: _StyleCard(profile: styleProfile)),
            ],
          ),
        ),
        const SizedBox(height: gap),
        const _AnalyzeCard(),
        if (latest == null) ...[
          const SizedBox(height: gap),
          const _GuideCard(),
        ],
      ],
    );
  }
}

/// 최근 보정한 사진 — 맨 위 큰 카드.
class _LatestCard extends StatelessWidget {
  final AnalysisRecord record;
  const _LatestCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      height: 220,
      padding: EdgeInsets.zero,
      onTap: () => _openRecord(context, record),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _RecordImage(path: record.thumbnailPath ?? record.imagePath),
          Positioned(
            left: 14,
            top: 14,
            child: _OverlayChip(
              text: '최근 보정 · ${record.styleCategory}',
            ),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Text(
              _formatDate(record.createdAt),
              style: AppTypography.number.copyWith(
                fontSize: 13,
                letterSpacing: 0,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 기록이 없을 때 맨 위 큰 카드.
class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard();

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      height: 220,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.photo_outlined, size: 32, color: context.instaSecondary),
          const SizedBox(height: 14),
          Text(
            '아직 분석한 사진이 없어요',
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 20,
              color: context.instaPrimaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '사진 한 장으로 내 감도를 찾아보세요',
            style: AppTypography.secondary.copyWith(color: context.instaSecondary),
          ),
        ],
      ),
    );
  }
}

/// 라임 카드 — 분석한 사진 수.
class _CountCard extends StatelessWidget {
  final int count;
  const _CountCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      color: AppColors.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '분석한 사진',
            style: AppTypography.badge.copyWith(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 28),
          Text(
            '$count',
            style: AppTypography.number.copyWith(
              fontSize: 56,
              letterSpacing: -2.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count == 0 ? '첫 장을 기다려요' : '장 보정했어요',
            style: AppTypography.meta.copyWith(fontSize: 12, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// 흰 카드 — 내 감도 (스타일 프로필의 대표 색과 대표 스타일).
class _StyleCard extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const _StyleCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?['primaryStyle'] as String?;
    final colorPref = profile?['colorPreference'];
    final raw = colorPref is Map ? colorPref['dominantColors'] : null;
    final colors = <Color>[
      if (raw is List)
        for (final c in raw.take(4))
          if (c is String && c.startsWith('#')) c.toColor(),
    ];

    return _BentoCard(
      onTap: () => context.go(AppRoutes.settings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 감도',
            style: AppTypography.badge.copyWith(
              fontSize: 13,
              color: context.instaSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final c in colors.isEmpty ? _placeholder(context) : colors)
                Expanded(
                  child: Container(
                    height: 34,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name ?? '아직 몰라요',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 18,
              color: context.instaPrimaryText,
            ),
          ),
          if (name == null)
            Text(
              '인스타그램을 연결해 보세요',
              style: AppTypography.meta.copyWith(
                fontSize: 12,
                color: context.instaSecondary,
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _placeholder(BuildContext context) =>
      List.filled(4, context.instaDivider);
}

/// 먹색 카드 — 새 사진 분석.
class _AnalyzeCard extends StatelessWidget {
  const _AnalyzeCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final fg = isDark ? AppColors.ink : Colors.white;
    final sub = isDark ? AppColors.textSecondaryLight : AppColors.textSecondaryDark;

    return Semantics(
      button: true,
      label: '새 사진 분석하기',
      excludeSemantics: true,
      child: _BentoCard(
        color: fill,
        height: 84,
        padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
        onTap: () => context.push(AppRoutes.photoUpload),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '새 사진 분석하기',
                    style: AppTypography.sectionTitle.copyWith(color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '내 감도로 자동 보정',
                    style: AppTypography.meta.copyWith(fontSize: 12, color: sub),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.highlight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.ink, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

/// 기록이 없을 때 — 사용법 세 단계.
class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      '사진을 고르거나 카메라로 찍어요',
      'AI가 색감·구도·톤을 읽어요',
      '내 감도로 보정한 결과를 저장해요',
    ];
    return _BentoCard(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12),
              child: Row(
                children: [
                  Text(
                    '0${i + 1}',
                    style: AppTypography.number.copyWith(
                      fontSize: 15,
                      letterSpacing: 0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppTypography.caption.copyWith(color: context.instaPrimaryText),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 지난 기록 — 둥근 사진 타일 두 열. 길게 누르면 변형·공유.
class _RecordGrid extends StatelessWidget {
  final List<AnalysisRecord> records;
  const _RecordGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: HomeScreen._gap,
        crossAxisSpacing: HomeScreen._gap,
        childAspectRatio: 0.82,
      ),
      itemCount: records.length,
      itemBuilder: (context, i) => _RecordTile(record: records[i]),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AnalysisRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openRecord(context, record),
      onLongPress: () => showInstaSheet(
        context,
        title: record.styleCategory,
        actions: [
          InstaSheetAction(
            icon: Icons.auto_fix_high_outlined,
            label: '사진 변형',
            onTap: () => context.push(
              AppRoutes.transform,
              extra: {
                'recordId': record.id,
                'imagePath': record.imagePath,
                'analysisJson': record.analysisJson,
              },
            ),
          ),
          InstaSheetAction(
            icon: Icons.ios_share_outlined,
            label: '공유',
            onTap: () => SharePlus.instance.share(
              ShareParams(
                text: '감도 분석 결과\n'
                    '스타일: ${record.styleCategory}\n'
                    '#감도 #사진분석 #AI코칭',
              ),
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _RecordImage(path: record.thumbnailPath ?? record.imagePath),
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: _OverlayChip(text: record.styleCategory),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사진 위에 얹는 흰 알약 라벨.
class _OverlayChip extends StatelessWidget {
  final String text;
  const _OverlayChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.badge.copyWith(color: AppColors.ink),
      ),
    );
  }
}

class _RecordImage extends StatelessWidget {
  final String path;
  const _RecordImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: context.instaDivider,
      child: Center(
        child: Icon(Icons.image_outlined, size: 36, color: context.instaSecondary),
      ),
    );
  }
}

void _openRecord(BuildContext context, AnalysisRecord record) {
  context.push(
    AppRoutes.analysisResult,
    extra: {
      'analysisId': record.id,
      'analysisJson': record.analysisJson,
      'imagePath': record.imagePath,
      'transformedImagePath': record.thumbnailPath,
    },
  );
}

String _formatDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

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
      // 5초 사이 새 분석이 시작됐으면 그 상태를 지우지 않도록,
      // 지금 완료된 실행일 때만 초기화한다.
      final notifier = ref.read(styleAnalysisPipelineProvider.notifier);
      final completedRun = notifier.runId;
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          ref
              .read(styleAnalysisPipelineProvider.notifier)
              .resetIfCompletedRun(completedRun);
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.1)
            : isCompleted
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.3)
              : isCompleted
                  ? AppColors.success.withValues(alpha: 0.3)
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
              color: isCompleted ? AppColors.success : AppColors.error,
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

