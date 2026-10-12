import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/photo_viewer.dart';
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
          // 벤토: 보정 전·후 사진 카드 → 라임 점수 카드 + 스타일 카드
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BeforeAfterCards(
                  beforePath: imagePath,
                  afterPath: transformedImagePath,
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

/// 보정 전·후 사진을 한 장 크기의 카드로 넘겨 본다.
///
/// 보정 후가 먼저 보이고, 오른쪽으로 넘기면(이전 장) 보정 전이 나온다.
/// 수평 맞추기·크롭이 들어간 결과는 원본과 프레임이 달라, 한 장에 겹쳐 놓고
/// 경계선을 끄는 비교는 위치가 어긋난다. 그래서 두 장을 따로 넘겨 보고,
/// 누르면 전체 화면 뷰어(확대·전후 전환·길게 눌러 원본)를 그 사진으로 연다.
/// 보정 후 사진이 없는 예전 기록은 원본 한 장만 보여 준다.
class _BeforeAfterCards extends StatefulWidget {
  final String? beforePath;
  final String? afterPath;

  const _BeforeAfterCards({required this.beforePath, required this.afterPath});

  @override
  State<_BeforeAfterCards> createState() => _BeforeAfterCardsState();
}

class _BeforeAfterCardsState extends State<_BeforeAfterCards> {
  static const double _height = 420;

  late final bool _hasBefore = _exists(widget.beforePath);
  late final bool _hasAfter = _exists(widget.afterPath);
  // 0 = 보정 전, 1 = 보정 후. 보정 후가 있으면 그 장에서 시작한다.
  late int _page = _hasAfter ? 1 : 0;
  late final PageController _controller = PageController(initialPage: _page);

  static bool _exists(String? path) => path != null && File(path).existsSync();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(int index) async {
    final before = widget.beforePath;
    if (!_hasBefore) return;
    Uint8List? afterBytes;
    if (_hasAfter) {
      try {
        afterBytes = await File(widget.afterPath!).readAsBytes();
      } catch (_) {
        afterBytes = null;
      }
    }
    if (!mounted) return;
    await PhotoViewerScreen.open(
      context,
      originalImage: File(before!),
      transformedBytes: afterBytes,
      initialIndex: afterBytes == null ? 0 : index,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAfter) {
      return _PhotoCard(
        path: _hasBefore ? widget.beforePath : null,
        label: '원본',
        highlight: false,
        height: _height,
        onTap: _hasBefore ? () => _open(0) : null,
      );
    }
    final pages = [
      _PhotoCard(
        path: _hasBefore ? widget.beforePath : null,
        label: '보정 전',
        highlight: false,
        height: _height,
        onTap: _hasBefore ? () => _open(0) : null,
      ),
      _PhotoCard(
        path: widget.afterPath,
        label: '보정 후',
        highlight: true,
        height: _height,
        onTap: _hasBefore ? () => _open(1) : null,
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: _height,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: pages,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: _page == 1
              ? '보정 후 사진, 2장 중 2번째'
              : '보정 전 사진, 2장 중 1번째',
          excludeSemantics: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? context.instaPrimaryText : context.instaDivider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String? path;
  final String label;
  final bool highlight;
  final double height;
  final VoidCallback? onTap;

  const _PhotoCard({
    required this.path,
    required this.label,
    required this.highlight,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label 사진${onTap != null ? ', 눌러서 크게 보기' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (path != null)
                  Image.file(File(path!), fit: BoxFit.cover)
                else
                  ColoredBox(color: context.instaDivider),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: highlight
                          ? AppColors.highlight
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.badge.copyWith(color: AppColors.ink),
                    ),
                  ),
                ),
                if (onTap != null)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.open_in_full_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
