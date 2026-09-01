import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/score_indicator.dart';
import '../domain/photo_analysis.dart';
import 'transform_provider.dart';
import 'widgets/color_palette_view.dart';
import 'widgets/color_temperature_gauge.dart';
import 'widgets/saturation_chart.dart';
import 'widgets/tone_report_card.dart';
import 'widgets/copyable_card.dart';
import 'widgets/tips_card.dart';
import '../../settings/providers/settings_provider.dart';

class TransformScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String analysisJson;

  const TransformScreen({
    super.key,
    required this.imagePath,
    required this.analysisJson,
  });

  @override
  ConsumerState<TransformScreen> createState() => _TransformScreenState();
}

class _TransformScreenState extends ConsumerState<TransformScreen> {
  Timer? _debounceTimer;
  late File _imageFile;
  late Map<String, dynamic> _analysis;

  double _dividerPosition = 0.5;

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    _analysis = jsonDecode(widget.analysisJson) as Map<String, dynamic>;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(transformProvider);
      if (state.status != TransformStatus.ready ||
          state.transformedImageBytes == null) {
        ref.read(transformProvider.notifier).analyzeAndTransform(_imageFile);
      }
      // 대표 사진 로드
      ref.read(transformProvider.notifier).loadReferenceImages();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSliderChanged(TransformParams newParams) {
    ref.read(transformProvider.notifier).updateParamsOnly(newParams);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(transformProvider.notifier).applyManual(_imageFile, newParams);
    });
  }

  Future<void> _onSave() async {
    final path =
        await ref.read(transformProvider.notifier).saveTransformedImage();
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('변형된 사진이 저장되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transformState = ref.watch(transformProvider);
    final isLoading =
        transformState.status == TransformStatus.loadingAutoTransform;
    final isApplying =
        transformState.status == TransformStatus.applyingManual;
    final isSaving = transformState.status == TransformStatus.saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 & 변형'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          if (transformState.transformedImageBytes != null)
            TextButton(
              onPressed: isSaving ? null : _onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '저장',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI가 사진을 분석하고 변형하는 중...'),
                ],
              ),
            )
          : transformState.status == TransformStatus.error
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          transformState.errorMessage ?? '오류가 발생했습니다',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(transformProvider.notifier)
                                .analyzeAndTransform(_imageFile);
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  children: [
                    // ── 0. 피드 미리보기 그리드 ──
                    if (transformState.referenceImages != null &&
                        transformState.referenceImages!.isNotEmpty &&
                        transformState.transformedImageBytes != null)
                      _FeedPreviewGrid(
                        referenceImages: transformState.referenceImages!,
                        transformedImage: transformState.transformedImageBytes!,
                      ),

                    // ── 1. Before/After 이미지 ──
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: _BeforeAfterView(
                        originalImage: _imageFile,
                        transformedBytes:
                            transformState.transformedImageBytes,
                        dividerPosition: _dividerPosition,
                        isApplying: isApplying,
                        onDividerChanged: (pos) {
                          setState(() => _dividerPosition = pos);
                        },
                      ),
                    ),

                    // ── 1.5. 얼굴/체형 보정 ──
                    _ReshapeSection(
                      params: transformState.params,
                      onChanged: _onSliderChanged,
                    ),

                    // ── 2. 톤 커브 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ToneCurveCard(
                        preset: transformState.params.toneCurvePreset,
                        strength: transformState.params.toneCurveStrength,
                        onChanged: (preset, strength) => _onSliderChanged(
                          transformState.params.copyWith(
                            toneCurvePreset: preset,
                            toneCurveStrength: strength,
                          ),
                        ),
                      ),
                    ),

                    // ── 3. 스플릿 토닝 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _SplitToningCard(
                        shadowHue: transformState.params.splitShadowHue,
                        shadowStrength: transformState.params.splitShadowStrength,
                        highlightHue: transformState.params.splitHighlightHue,
                        highlightStrength: transformState.params.splitHighlightStrength,
                        onChanged: (shHue, shStr, hlHue, hlStr) =>
                            _onSliderChanged(
                          transformState.params.copyWith(
                            splitShadowHue: shHue,
                            splitShadowStrength: shStr,
                            splitHighlightHue: hlHue,
                            splitHighlightStrength: hlStr,
                          ),
                        ),
                      ),
                    ),

                    // ── 4. HSL 선택적 색상 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _HslAdjustCard(
                        hslAdjust: transformState.params.hslAdjust,
                        onChanged: (hsl) => _onSliderChanged(
                          transformState.params.copyWith(hslAdjust: hsl),
                        ),
                      ),
                    ),

                    // ── 5. 보정 슬라이더 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _SectionTitle(icon: Icons.tune, title: '보정'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _TransformSlider(
                            label: '밝기',
                            icon: Icons.brightness_6_outlined,
                            value: transformState.params.brightness,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(brightness: v)),
                          ),
                          _TransformSlider(
                            label: '대비',
                            icon: Icons.contrast_outlined,
                            value: transformState.params.contrast,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(contrast: v)),
                          ),
                          _TransformSlider(
                            label: '선명감',
                            icon: Icons.hdr_strong_outlined,
                            value: transformState.params.clarity,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(clarity: v)),
                          ),
                          _TransformSlider(
                            label: '안개 제거',
                            icon: Icons.cloud_off_outlined,
                            value: transformState.params.dehaze,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(dehaze: v)),
                          ),
                          _TransformSlider(
                            label: '하이라이트',
                            icon: Icons.wb_sunny_outlined,
                            value: transformState.params.highlights,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(highlights: v)),
                          ),
                          _TransformSlider(
                            label: '쉐도우',
                            icon: Icons.nights_stay_outlined,
                            value: transformState.params.shadows,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(shadows: v)),
                          ),
                          _TransformSlider(
                            label: '채도',
                            icon: Icons.palette_outlined,
                            value: transformState.params.saturation,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(saturation: v)),
                          ),
                          _TransformSlider(
                            label: '색온도',
                            icon: Icons.thermostat_outlined,
                            value: transformState.params.temperature,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(temperature: v)),
                            coolWarmGradient: true,
                          ),
                          _TransformSlider(
                            label: '잡티 제거',
                            icon: Icons.auto_fix_high_outlined,
                            value: transformState.params.blemishRemoval,
                            min: 0.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params
                                    .copyWith(blemishRemoval: v)),
                          ),
                          _TransformSlider(
                            label: '피부 보정',
                            icon: Icons.face_outlined,
                            value: transformState.params.skinSmoothing,
                            min: 0.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params
                                    .copyWith(skinSmoothing: v)),
                          ),
                          _TransformSlider(
                            label: '비네팅',
                            icon: Icons.vignette_outlined,
                            value: transformState.params.vignette,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(vignette: v)),
                          ),
                          _TransformSlider(
                            label: '선명도',
                            icon: Icons.deblur_outlined,
                            value: transformState.params.sharpness,
                            min: -1.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(sharpness: v)),
                          ),
                          _TransformSlider(
                            label: '그레인',
                            icon: Icons.grain_outlined,
                            value: transformState.params.grain,
                            min: 0.0, max: 1.0,
                            onChanged: (v) => _onSliderChanged(
                                transformState.params.copyWith(grain: v)),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 32, indent: 20, endIndent: 20),

                    // ── 6. 분석 결과 ──
                    _AnalysisSection(analysis: _analysis),

                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}

// ── 섹션 헤더 ──

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 얼굴/체형 보정 섹션 ──

class _ReshapeSection extends ConsumerWidget {
  final TransformParams params;
  final ValueChanged<TransformParams> onChanged;

  const _ReshapeSection({
    required this.params,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reshapeAsync = ref.watch(reshapeEnabledSettingProvider);
    final isEnabled = reshapeAsync.value ?? false;

    if (!isEnabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _ReshapeCard(
        params: params,
        onChanged: onChanged,
      ),
    );
  }
}

class _ReshapeCard extends StatefulWidget {
  final TransformParams params;
  final ValueChanged<TransformParams> onChanged;

  const _ReshapeCard({
    required this.params,
    required this.onChanged,
  });

  @override
  State<_ReshapeCard> createState() => _ReshapeCardState();
}

class _ReshapeCardState extends State<_ReshapeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.params.faceSlim > 0.01 ||
        widget.params.jawSharpen > 0.01 ||
        widget.params.eyeEnlarge > 0.01 ||
        widget.params.legStretch > 0.01 ||
        widget.params.shoulderWidth.abs() > 0.01 ||
        widget.params.waistSlim > 0.01;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.face_retouching_natural,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '얼굴/체형 보정',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 얼굴 보정
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      '얼굴',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  _TransformSlider(
                    label: '얼굴 축소',
                    icon: Icons.face_outlined,
                    value: widget.params.faceSlim,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => widget.onChanged(
                        widget.params.copyWith(faceSlim: v)),
                  ),
                  _TransformSlider(
                    label: '턱선',
                    icon: Icons.architecture_outlined,
                    value: widget.params.jawSharpen,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => widget.onChanged(
                        widget.params.copyWith(jawSharpen: v)),
                  ),
                  _TransformSlider(
                    label: '눈 확대',
                    icon: Icons.visibility_outlined,
                    value: widget.params.eyeEnlarge,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => widget.onChanged(
                        widget.params.copyWith(eyeEnlarge: v)),
                  ),
                  const SizedBox(height: 8),
                  // 체형 보정
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      '체형',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  _TransformSlider(
                    label: '다리 늘리기',
                    icon: Icons.straighten_outlined,
                    value: widget.params.legStretch,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => widget.onChanged(
                        widget.params.copyWith(legStretch: v)),
                  ),
                  _TransformSlider(
                    label: '어깨 너비',
                    icon: Icons.open_in_full_outlined,
                    value: widget.params.shoulderWidth,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (v) => widget.onChanged(
                        widget.params.copyWith(shoulderWidth: v)),
                  ),
                  _TransformSlider(
                    label: '허리 라인',
                    icon: Icons.compress_outlined,
                    value: widget.params.waistSlim,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => widget.onChanged(
                        widget.params.copyWith(waistSlim: v)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 자동 편집 안내 배너 ──

class _AutoEditBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String reason;
  const _AutoEditBanner({
    required this.icon,
    required this.label,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

// ── 분석 결과 섹션 ──

class _AnalysisSection extends StatelessWidget {
  final Map<String, dynamic> analysis;
  const _AnalysisSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final autoEdits = analysis['autoEdits'] as Map<String, dynamic>? ?? {};
    final cropReason = autoEdits['cropReason'] as String?;

    PhotoAnalysisResponse? parsed;
    try {
      parsed = PhotoAnalysisResponse.fromJson(analysis);
    } catch (_) {}

    if (parsed != null) {
      return _ParsedAnalysis(analysis: parsed, cropReason: cropReason);
    }
    return _RawAnalysis(analysis: analysis);
  }
}

class _ParsedAnalysis extends StatelessWidget {
  final PhotoAnalysisResponse analysis;
  final String? cropReason;
  const _ParsedAnalysis({required this.analysis, this.cropReason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.analytics_outlined, title: '분석'),
          const SizedBox(height: 4),

          // 자동 크롭 안내
          if (cropReason != null && cropReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AutoEditBanner(
                icon: Icons.crop,
                label: '자동 크롭 적용',
                reason: cropReason!,
              ),
            ),

          // 점수 + 톤 리포트
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScoreIndicator(score: analysis.overallScore, size: 52),
              const SizedBox(width: 12),
              Expanded(child: ToneReportCard(toneReport: analysis.toneReport)),
            ],
          ),
          const SizedBox(height: 12),

          // 색감
          ColorPaletteView(
            colors: analysis.colorAnalysis.dominantColors,
            description: analysis.colorAnalysis.paletteDescription,
          ),
          const SizedBox(height: 8),
          ColorTemperatureGauge(
            temperature: analysis.colorAnalysis.colorTemperature,
          ),
          const SizedBox(height: 8),
          SaturationChart(
            saturation: analysis.colorAnalysis.saturationLevel,
            brightness: analysis.colorAnalysis.brightnessLevel,
          ),
          const SizedBox(height: 12),

          // 팁
          if (analysis.shootingTips.isNotEmpty)
            TipsCard(
              title: '촬영 팁',
              tips: analysis.shootingTips,
              icon: Icons.camera_alt_outlined,
              color: AppColors.primary,
            ),
          if (analysis.editingTips.isNotEmpty) ...[
            const SizedBox(height: 8),
            TipsCard(
              title: '보정 팁',
              tips: analysis.editingTips,
              icon: Icons.tune_outlined,
              color: AppColors.accent,
            ),
          ],
          if (analysis.hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            HashtagCard(
              title: '해시태그',
              hashtags: analysis.hashtags,
              icon: Icons.tag,
              color: AppColors.primaryDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _RawAnalysis extends StatelessWidget {
  final Map<String, dynamic> analysis;
  const _RawAnalysis({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final tone = analysis['toneReport'] as Map<String, dynamic>? ?? {};
    final style = tone['styleCategory'] as String? ?? '';
    final mood = tone['overallMood'] as String? ?? '';
    final narrative = tone['narrative'] as String? ?? '';
    final score = (analysis['overallScore'] as num?)?.toInt() ?? 0;
    final shootingTips =
        (analysis['shootingTips'] as List<dynamic>?)?.cast<String>() ?? [];
    final editingTips =
        (analysis['editingTips'] as List<dynamic>?)?.cast<String>() ?? [];
    final hashtags =
        (analysis['hashtags'] as List<dynamic>?)?.cast<String>() ?? [];
    final autoEdits =
        analysis['autoEdits'] as Map<String, dynamic>? ?? {};
    final cropReason = autoEdits['cropReason'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.analytics_outlined, title: '분석'),
          const SizedBox(height: 4),
          if (cropReason != null && cropReason.isNotEmpty) ...[
            _AutoEditBanner(
              icon: Icons.crop,
              label: '자동 크롭 적용',
              reason: cropReason,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (score > 0) ...[
                ScoreIndicator(score: score, size: 52),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (style.isNotEmpty) _badge(context, style, AppColors.primary),
                    if (mood.isNotEmpty) _badge(context, mood, AppColors.accent),
                  ],
                ),
              ),
            ],
          ),
          if (narrative.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(narrative, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (shootingTips.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...shootingTips.map((t) => _tipRow(context, Icons.camera_alt, t)),
          ],
          if (editingTips.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...editingTips.map((t) => _tipRow(context, Icons.tune, t)),
          ],
          if (hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            HashtagCard(
              title: '해시태그',
              hashtags: hashtags,
              icon: Icons.tag,
              color: AppColors.primaryDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _tipRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ── 피드 미리보기 그리드 ──

class _FeedPreviewGrid extends StatelessWidget {
  final List<Uint8List> referenceImages;
  final Uint8List transformedImage;

  const _FeedPreviewGrid({
    required this.referenceImages,
    required this.transformedImage,
  });

  @override
  Widget build(BuildContext context) {
    // 3열 그리드: [대표1] [변형된 사진] [대표2]
    // 대표 사진이 1장이면: [대표1] [변형된 사진] [빈칸]
    final ref0 = referenceImages.isNotEmpty ? referenceImages[0] : null;
    final ref1 = referenceImages.length > 1 ? referenceImages[1] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_on, size: 16,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '피드 미리보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _gridCell(context, ref0, '대표 1')),
              const SizedBox(width: 2),
              Expanded(child: _gridCell(context, transformedImage, '변형')),
              const SizedBox(width: 2),
              Expanded(child: _gridCell(context, ref1, '대표 2')),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _gridCell(BuildContext context, Uint8List? imageBytes, String label) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageBytes != null
            ? Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            : Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Before/After 비교 뷰 ──

class _BeforeAfterView extends StatelessWidget {
  final File originalImage;
  final Uint8List? transformedBytes;
  final double dividerPosition;
  final bool isApplying;
  final ValueChanged<double> onDividerChanged;

  const _BeforeAfterView({
    required this.originalImage,
    required this.transformedBytes,
    required this.dividerPosition,
    required this.isApplying,
    required this.onDividerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final newPos = details.localPosition.dx / width;
            onDividerChanged(newPos.clamp(0.0, 1.0));
          },
          child: Stack(
            children: [
              if (transformedBytes != null)
                Positioned.fill(
                  child: Image.memory(transformedBytes!,
                      fit: BoxFit.contain, gaplessPlayback: true),
                )
              else
                Positioned.fill(
                  child: Image.file(originalImage, fit: BoxFit.contain),
                ),
              Positioned.fill(
                child: ClipRect(
                  clipper: _LeftClipper(dividerPosition),
                  child: Image.file(originalImage, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                left: width * dividerPosition - 1,
                top: 0, bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: width * dividerPosition - 16,
                top: 0, bottom: 0,
                child: Center(
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.swap_horiz,
                        size: 18, color: Colors.black54),
                  ),
                ),
              ),
              Positioned(left: 12, top: 12, child: _Label('Before')),
              Positioned(right: 12, top: 12, child: _Label('After')),
              if (isApplying)
                Positioned(
                  right: 12, bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  _LeftClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => fraction != old.fraction;
}

// ── 슬라이더 ──

class _TransformSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final bool coolWarmGradient;

  const _TransformSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.coolWarmGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: coolWarmGradient
                    ? (value >= 0 ? AppColors.warmColor : AppColors.coolColor)
                    : null,
              ),
              child: Slider(
                  value: value, min: min, max: max, onChanged: onChanged),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              displayValue > 0 ? '+$displayValue' : '$displayValue',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 톤 커브 카드 ──

class _ToneCurveCard extends StatefulWidget {
  final String preset;
  final double strength;
  final void Function(String preset, double strength) onChanged;

  const _ToneCurveCard({
    required this.preset,
    required this.strength,
    required this.onChanged,
  });

  @override
  State<_ToneCurveCard> createState() => _ToneCurveCardState();
}

class _ToneCurveCardState extends State<_ToneCurveCard> {
  bool _expanded = false;

  static const _presets = [
    ('linear', '기본'),
    ('s_curve', 'S커브'),
    ('film', '필름'),
    ('fade', '페이드'),
    ('high_contrast', '고대비'),
    ('bright', '밝게'),
  ];

  // 프리셋별 제어점 (커브 미리보기용)
  static const Map<String, List<List<double>>> _presetPoints = {
    'linear': [[0, 0], [0.25, 0.25], [0.5, 0.5], [0.75, 0.75], [1, 1]],
    's_curve': [[0, 0], [0.25, 0.18], [0.5, 0.5], [0.75, 0.82], [1, 1]],
    'film': [[0, 0.05], [0.25, 0.22], [0.5, 0.52], [0.75, 0.78], [1, 0.95]],
    'fade': [[0, 0.08], [0.25, 0.28], [0.5, 0.50], [0.75, 0.72], [1, 0.92]],
    'high_contrast': [[0, 0], [0.25, 0.12], [0.5, 0.5], [0.75, 0.88], [1, 1]],
    'bright': [[0, 0.04], [0.25, 0.30], [0.5, 0.56], [0.75, 0.80], [1, 1]],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.preset != 'linear' && widget.strength > 0.01;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // 헤더 (탭하면 확장/접기)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.show_chart,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '톤 커브',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _presets
                            .firstWhere((p) => p.$1 == widget.preset,
                                orElse: () => ('linear', '기본'))
                            .$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // 소형 커브 미리보기
                  SizedBox(
                    width: 40,
                    height: 28,
                    child: CustomPaint(
                      painter: _ToneCurvePreviewPainter(
                        points: _presetPoints[widget.preset] ??
                            _presetPoints['linear']!,
                        strength: widget.strength,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          // 확장된 내용
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                children: [
                  // 프리셋 칩 가로 스크롤
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final (key, label) = _presets[index];
                        final selected = widget.preset == key;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) {
                            final newStrength = key == 'linear'
                                ? 0.0
                                : (widget.strength < 0.01 ? 0.5 : widget.strength);
                            widget.onChanged(key, newStrength);
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 커브 미리보기 (큰 버전)
                  Center(
                    child: SizedBox(
                      width: 80,
                      height: 60,
                      child: CustomPaint(
                        painter: _ToneCurvePreviewPainter(
                          points: _presetPoints[widget.preset] ??
                              _presetPoints['linear']!,
                          strength: widget.strength,
                          color: theme.colorScheme.primary,
                          showGrid: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 강도 슬라이더
                  Row(
                    children: [
                      Text(
                        '강도',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                          ),
                          child: Slider(
                            value: widget.strength,
                            min: 0.0,
                            max: 1.0,
                            onChanged: widget.preset == 'linear'
                                ? null
                                : (v) =>
                                    widget.onChanged(widget.preset, v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${(widget.strength * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 톤 커브 프리뷰 페인터 ──

class _ToneCurvePreviewPainter extends CustomPainter {
  final List<List<double>> points;
  final double strength;
  final Color color;
  final bool showGrid;

  _ToneCurvePreviewPainter({
    required this.points,
    required this.strength,
    required this.color,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 배경 그리드
    if (showGrid) {
      final gridPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..strokeWidth = 0.5;
      for (var i = 1; i < 4; i++) {
        final x = w * i / 4;
        final y = h * i / 4;
        canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
        canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      }
    }

    // 대각선 (identity)
    final diagPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h), Offset(w, 0), diagPaint);

    // 커브 그리기 — 제어점을 보간하여 부드러운 곡선 생성
    final curvePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      // np.interp 상당: 제어점 사이 선형 보간
      double curveY = t;
      for (var j = 0; j < points.length - 1; j++) {
        if (t >= points[j][0] && t <= points[j + 1][0]) {
          final frac = (t - points[j][0]) / (points[j + 1][0] - points[j][0]);
          curveY = points[j][1] + frac * (points[j + 1][1] - points[j][1]);
          break;
        }
      }
      // identity와 블렌딩
      final y = t * (1 - strength) + curveY * strength;
      final px = t * w;
      final py = (1 - y) * h;

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(_ToneCurvePreviewPainter oldDelegate) =>
      points != oldDelegate.points ||
      strength != oldDelegate.strength ||
      color != oldDelegate.color;
}

// ── 스플릿 토닝 카드 ──

class _SplitToningCard extends StatefulWidget {
  final double shadowHue;
  final double shadowStrength;
  final double highlightHue;
  final double highlightStrength;
  final void Function(
      double shadowHue, double shadowStrength,
      double highlightHue, double highlightStrength) onChanged;

  const _SplitToningCard({
    required this.shadowHue,
    required this.shadowStrength,
    required this.highlightHue,
    required this.highlightStrength,
    required this.onChanged,
  });

  @override
  State<_SplitToningCard> createState() => _SplitToningCardState();
}

class _SplitToningCardState extends State<_SplitToningCard> {
  bool _expanded = false;

  // 대표적인 색상 프리셋 (hue, label, Color)
  static final _huePresets = [
    (0.0, '빨강', const Color(0xFFE53935)),
    (30.0, '오렌지', const Color(0xFFFF8A00)),
    (60.0, '노랑', const Color(0xFFFDD835)),
    (120.0, '녹색', const Color(0xFF43A047)),
    (180.0, '시안', const Color(0xFF00ACC1)),
    (210.0, '틸', const Color(0xFF0097A7)),
    (240.0, '파랑', const Color(0xFF1E88E5)),
    (270.0, '보라', const Color(0xFF7B1FA2)),
    (300.0, '마젠타', const Color(0xFFAD1457)),
    (330.0, '핑크', const Color(0xFFE91E63)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive =
        widget.shadowStrength > 0.01 || widget.highlightStrength > 0.01;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // 헤더
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.color_lens_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '스플릿 토닝',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    // 쉐도우/하이라이트 색상 미리보기 원
                    if (widget.shadowStrength > 0.01)
                      _colorDot(_hueToColor(widget.shadowHue)),
                    if (widget.shadowStrength > 0.01 &&
                        widget.highlightStrength > 0.01)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.arrow_forward,
                            size: 10, color: Colors.grey),
                      ),
                    if (widget.highlightStrength > 0.01)
                      _colorDot(_hueToColor(widget.highlightHue)),
                  ],
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 쉐도우 섹션 ──
                  Text('쉐도우 색조',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7))),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _huePresets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final (hue, label, color) = _huePresets[index];
                        final selected =
                            (widget.shadowHue - hue).abs() < 1.0 &&
                                widget.shadowStrength > 0.01;
                        return GestureDetector(
                          onTap: () {
                            final newStr = widget.shadowStrength < 0.01
                                ? 0.2
                                : widget.shadowStrength;
                            widget.onChanged(hue, newStr,
                                widget.highlightHue, widget.highlightStrength);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 2.5)
                                  : Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                      width: 1),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Text('강도',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7))),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor:
                                _hueToColor(widget.shadowHue),
                          ),
                          child: Slider(
                            value: widget.shadowStrength,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (v) => widget.onChanged(
                                widget.shadowHue, v,
                                widget.highlightHue,
                                widget.highlightStrength),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${(widget.shadowStrength * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── 하이라이트 섹션 ──
                  Text('하이라이트 색조',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7))),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _huePresets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final (hue, label, color) = _huePresets[index];
                        final selected =
                            (widget.highlightHue - hue).abs() < 1.0 &&
                                widget.highlightStrength > 0.01;
                        return GestureDetector(
                          onTap: () {
                            final newStr = widget.highlightStrength < 0.01
                                ? 0.2
                                : widget.highlightStrength;
                            widget.onChanged(widget.shadowHue,
                                widget.shadowStrength, hue, newStr);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 2.5)
                                  : Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                      width: 1),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Text('강도',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7))),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor:
                                _hueToColor(widget.highlightHue),
                          ),
                          child: Slider(
                            value: widget.highlightStrength,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (v) => widget.onChanged(
                                widget.shadowHue, widget.shadowStrength,
                                widget.highlightHue, v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${(widget.highlightStrength * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }

  static Color _hueToColor(double hue) {
    return HSVColor.fromAHSV(1.0, hue % 360.0, 0.8, 0.9).toColor();
  }
}

// ── HSL 선택적 색상 카드 ──

class _HslAdjustCard extends StatefulWidget {
  final Map<String, Map<String, double>>? hslAdjust;
  final ValueChanged<Map<String, Map<String, double>>> onChanged;

  const _HslAdjustCard({
    required this.hslAdjust,
    required this.onChanged,
  });

  @override
  State<_HslAdjustCard> createState() => _HslAdjustCardState();
}

class _HslAdjustCardState extends State<_HslAdjustCard> {
  bool _expanded = false;
  String _selectedChannel = 'orange';

  static const _channels = [
    ('red', '빨강', Color(0xFFE53935)),
    ('orange', '오렌지', Color(0xFFFF8A00)),
    ('yellow', '노랑', Color(0xFFFDD835)),
    ('green', '녹색', Color(0xFF43A047)),
    ('cyan', '시안', Color(0xFF00ACC1)),
    ('blue', '파랑', Color(0xFF1E88E5)),
    ('purple', '보라', Color(0xFF7B1FA2)),
    ('magenta', '마젠타', Color(0xFFAD1457)),
  ];

  double _getVal(String channel, String key) {
    return widget.hslAdjust?[channel]?[key] ?? 0.0;
  }

  void _setVal(String channel, String key, double value) {
    final current =
        Map<String, Map<String, double>>.from(widget.hslAdjust ?? {});
    final ch = Map<String, double>.from(current[channel] ?? {
      'hue': 0.0,
      'saturation': 0.0,
      'lightness': 0.0,
    });
    ch[key] = value;

    // 전부 0이면 채널 제거
    if (ch.values.every((v) => v.abs() < 0.01)) {
      current.remove(channel);
    } else {
      current[channel] = ch;
    }
    widget.onChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount =
        widget.hslAdjust?.length ?? 0;
    final isActive = activeCount > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.palette_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'HSL 색상',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount색',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  // 색상 채널 선택 칩
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _channels.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final (key, label, color) = _channels[index];
                        final selected = _selectedChannel == key;
                        final hasAdj = widget.hslAdjust
                                ?.containsKey(key) ==
                            true;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedChannel = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? color
                                    : hasAdj
                                        ? color.withValues(alpha: 0.5)
                                        : theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: selected
                                        ? color
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 선택된 채널의 H/S/L 슬라이더
                  _HslSlider(
                    label: '색상',
                    value: _getVal(_selectedChannel, 'hue'),
                    color: _channels
                        .firstWhere((c) => c.$1 == _selectedChannel)
                        .$3,
                    onChanged: (v) =>
                        _setVal(_selectedChannel, 'hue', v),
                  ),
                  _HslSlider(
                    label: '채도',
                    value: _getVal(_selectedChannel, 'saturation'),
                    color: _channels
                        .firstWhere((c) => c.$1 == _selectedChannel)
                        .$3,
                    onChanged: (v) =>
                        _setVal(_selectedChannel, 'saturation', v),
                  ),
                  _HslSlider(
                    label: '밝기',
                    value: _getVal(_selectedChannel, 'lightness'),
                    color: _channels
                        .firstWhere((c) => c.$1 == _selectedChannel)
                        .$3,
                    onChanged: (v) =>
                        _setVal(_selectedChannel, 'lightness', v),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HslSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _HslSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7))),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: color,
              ),
              child: Slider(
                value: value,
                min: -1.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              displayValue > 0 ? '+$displayValue' : '$displayValue',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
