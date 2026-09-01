import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/instagram_widgets.dart';
import '../../../core/widgets/score_indicator.dart';
import '../domain/photo_analysis.dart';
import 'widgets/color_palette_view.dart';
import 'widgets/color_temperature_gauge.dart';
import 'widgets/saturation_chart.dart';
import 'widgets/composition_overlay.dart';
import 'widgets/tone_report_card.dart';
import 'widgets/tips_card.dart';

class AnalysisResultScreen extends StatelessWidget {
  final int? analysisId;
  final String? analysisJson;
  final String? imagePath;

  const AnalysisResultScreen({
    super.key,
    this.analysisId,
    this.analysisJson,
    this.imagePath,
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagePath != null)
                    Image.file(
                      File(imagePath!),
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
                  // Score overlay
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: ScoreIndicator(
                      score: analysis.overallScore,
                      size: 72,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis.toneReport.overallMood,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
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
                const SizedBox(height: 16),
                _CompositionDetails(
                  strengths: analysis.compositionAnalysis.strengths,
                  improvements: analysis.compositionAnalysis.improvements,
                ),
                const SizedBox(height: 24),

                // Tone Report Section
                _SectionHeader(title: context.l10n.toneReport),
                const SizedBox(height: 12),
                ToneReportCard(toneReport: analysis.toneReport),
                const SizedBox(height: 24),

                // Tips Section
                TipsCard(
                  title: context.l10n.shootingTips,
                  tips: analysis.shootingTips,
                  icon: Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                TipsCard(
                  title: context.l10n.editingTips,
                  tips: analysis.editingTips,
                  icon: Icons.tune_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 24),

                // 사진 변형 버튼
                if (imagePath != null)
                  InstagramGradientButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.transform,
                        extra: {
                          'imagePath': imagePath,
                          'analysisJson': analysisJson,
                        },
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          '사진 변형하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 20),
                const SizedBox(height: 32),
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
      style: context.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
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

class _CompositionDetails extends StatelessWidget {
  final List<String> strengths;
  final List<String> improvements;

  const _CompositionDetails({
    required this.strengths,
    required this.improvements,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strengths
            Row(
              children: [
                const Icon(Icons.thumb_up_outlined,
                    size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  context.l10n.strengths,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 26, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('- ', style: TextStyle(color: AppColors.success)),
                      Expanded(child: Text(s, style: context.textTheme.bodyMedium)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            // Improvements
            Row(
              children: [
                const Icon(Icons.lightbulb_outlined,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  context.l10n.improvements,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...improvements.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 26, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('- ', style: TextStyle(color: AppColors.warning)),
                      Expanded(child: Text(s, style: context.textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
