import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../domain/photo_analysis.dart';
import '../widgets/color_palette_view.dart';
import '../widgets/color_temperature_gauge.dart';
import '../widgets/saturation_chart.dart';
import '../widgets/composition_overlay.dart';
import '../widgets/tone_report_card.dart';

class AnalysisResultScreen extends StatelessWidget {
  final int? analysisId;
  final String? analysisJson;

  /// 분석 대상이 된 원본. 구도 분석 오버레이가 이 사진 위에 그려진다.
  final String? imagePath;

  /// 변형(after) 결과. 상단에 크게 보여 주는 그림이다.
  /// 없으면(v2 이전 기록) 원본으로 폴백한다.
  final String? transformedImagePath;

  const AnalysisResultScreen({
    super.key,
    this.analysisId,
    this.analysisJson,
    this.imagePath,
    this.transformedImagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (analysisJson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.error)),
        body: Center(child: Text(context.l10n.errorAnalysisFailed)),
      );
    }

    final analysisMap = jsonDecode(analysisJson!) as Map<String, dynamic>;

    final PhotoAnalysisResponse analysis;
    try {
      analysis = PhotoAnalysisResponse.fromJson(analysisMap);
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('분석 결과')),
        body: const Center(
          child: Text('이전 형식의 분석 데이터입니다.\n새로 분석해 주세요.',
              textAlign: TextAlign.center),
        ),
      );
    }

    final heroPath = transformedImagePath ?? imagePath;
    // 서버가 대표 사진과 견줘 잰 피드 어울림(0~100). 대표 사진이 없던 분석이나
    // 예전 기록에는 없다 — 그때는 점수 카드를 빼고 스타일 카드만 넓게 둔다.
    final score = (analysisMap['feedCompatibility'] as num?)?.round();
    final scoreBefore = (analysisMap['feedCompatibilityBefore'] as num?)?.round();

    void share() {
      final summary = StringBuffer()
        ..writeln('감도 분석 결과')
        ..writeln()
        ..writeln('스타일: ${analysis.toneReport.styleCategory}')
        ..writeln('분위기: ${analysis.toneReport.overallMood}')
        ..writeln()
        ..writeln('#감도 #사진분석 #AI코칭');
      SharePlus.instance.share(ShareParams(text: summary.toString()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: '뒤로',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('분석 결과'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 22),
            tooltip: '공유',
            onPressed: share,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 벤토: 큰 사진 카드 → 라임 점수 카드 + 스타일 카드
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 300,
                    child: heroPath != null
                        ? Image.file(File(heroPath), fit: BoxFit.cover)
                        : ColoredBox(color: context.instaDivider),
                  ),
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (score != null) ...[
                        Expanded(
                          child: _ScoreCard(score: score, before: scoreBefore),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: _StyleSummaryCard(
                          style: analysis.toneReport.styleCategory,
                          mood: analysis.toneReport.overallMood,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Color Analysis Section
                _SectionHeader(title: context.l10n.colorAnalysis),
                const SizedBox(height: 12),
                ColorPaletteView(
                  colors: analysis.colorAnalysis.dominantColors,
                  description: analysis.colorAnalysis.paletteDescription,
                ),
                const SizedBox(height: 16),
                ColorTemperatureGauge(
                  temperature: analysis.colorAnalysis.colorTemperature,
                ),
                const SizedBox(height: 16),
                SaturationChart(
                  saturation: analysis.colorAnalysis.saturationLevel,
                  brightness: analysis.colorAnalysis.brightnessLevel,
                ),
                const SizedBox(height: 16),
                _HarmonyCard(harmony: analysis.colorAnalysis.colorHarmony),
                const SizedBox(height: 24),

                // Composition Analysis Section
                _SectionHeader(title: context.l10n.compositionAnalysis),
                const SizedBox(height: 12),
                if (imagePath != null)
                  CompositionOverlay(
                    imagePath: imagePath!,
                    technique: analysis.compositionAnalysis.primaryTechnique,
                    balanceScore: analysis.compositionAnalysis.balanceScore,
                  ),
                const SizedBox(height: 24),

                // Tone Report Section
                _SectionHeader(title: context.l10n.toneReport),
                const SizedBox(height: 12),
                ToneReportCard(toneReport: analysis.toneReport),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.sectionTitle.copyWith(
        color: context.instaPrimaryText,
      ),
    );
  }
}

class _HarmonyCard extends StatelessWidget {
  final String harmony;

  const _HarmonyCard({required this.harmony});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.colorHarmony,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    harmony,
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 라임 카드 — 피드 어울림 점수.
class _ScoreCard extends StatelessWidget {
  final int score;
  final int? before;

  const _ScoreCard({required this.score, this.before});

  @override
  Widget build(BuildContext context) {
    final delta = before == null ? null : score - before!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.highlight,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '피드 어울림',
            style: AppTypography.badge.copyWith(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: AppTypography.number.copyWith(
                  fontSize: 56,
                  letterSpacing: -2.5,
                  color: AppColors.ink,
                ),
              ),
              if (delta != null && delta != 0) ...[
                const SizedBox(width: 6),
                Text(
                  delta > 0 ? '+$delta' : '$delta',
                  style: AppTypography.number.copyWith(
                    fontSize: 15,
                    letterSpacing: 0,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ],
          ),
          if (before != null) ...[
            const SizedBox(height: 4),
            Text(
              '보정 전 $before',
              style: AppTypography.meta.copyWith(fontSize: 12, color: AppColors.ink),
            ),
          ],
        ],
      ),
    );
  }
}

/// 흰 카드 — 스타일과 분위기.
class _StyleSummaryCard extends StatelessWidget {
  final String style;
  final String mood;

  const _StyleSummaryCard({required this.style, required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.instaSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '스타일',
            style: AppTypography.badge.copyWith(
              fontSize: 13,
              color: context.instaSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                style,
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 19,
                  color: context.instaPrimaryText,
                ),
              ),
              if (mood.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  mood,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.secondary.copyWith(
                    fontSize: 12,
                    color: context.instaSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
