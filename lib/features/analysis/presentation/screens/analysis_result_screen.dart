import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/context_extensions.dart';
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            // 사진 위에 헤어라인이 겹치지 않게 테마의 하단 선을 끈다
            shape: const Border(),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
                tooltip: '\uACF5\uC720',
                onPressed: () {
                  final summary = StringBuffer()
                    ..writeln('\uD83D\uDCF8 \uAC10\uB3C4 \uBD84\uC11D \uACB0\uACFC')
                    ..writeln()
                    ..writeln('\uC2A4\uD0C0\uC77C: ${analysis.toneReport.styleCategory}')
                    ..writeln('\uBD84\uC704\uAE30: ${analysis.toneReport.overallMood}')
                    ..writeln()
                    ..writeln('#\uAC10\uB3C4 #\uC0AC\uC9C4\uBD84\uC11D #AI\uCF54\uCE6D');
                  SharePlus.instance.share(
                    ShareParams(text: summary.toString()),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 사용자가 만든 결과물이 주인공이다. 원본은 아래 구도
                  // 분석에서만 쓴다.
                  if (heroPath != null)
                    Image.file(
                      File(heroPath),
                      fit: BoxFit.cover,
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis.toneReport.styleCategory,
                          style: context.textTheme.displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis.toneReport.overallMood,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
