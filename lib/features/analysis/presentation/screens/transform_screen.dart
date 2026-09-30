import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/instagram_share_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../../core/widgets/instagram_widgets.dart';
import '../../domain/photo_analysis.dart';
import '../providers/transform_provider.dart';
import '../widgets/color_palette_view.dart';
import '../widgets/color_temperature_gauge.dart';
import '../widgets/saturation_chart.dart';
import '../widgets/tone_report_card.dart';

class TransformScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String analysisJson;

  /// 기록(홈·기록 화면)에서 열었을 때의 분석 기록 id. 있으면 AI를 다시
  /// 부르지 않고 저장된 변형 값으로 복원하며, 다시 분석해도 새 기록을
  /// 만들지 않고 이 기록을 갱신한다.
  final int? recordId;

  const TransformScreen({
    super.key,
    required this.imagePath,
    required this.analysisJson,
    this.recordId,
  });

  @override
  ConsumerState<TransformScreen> createState() => _TransformScreenState();
}

class _TransformScreenState extends ConsumerState<TransformScreen> {
  late File _imageFile;
  bool _sharing = false;

  /// 인스타그램 설치 여부. 없으면 공유 버튼을 내리고 저장만 안내한다 —
  /// 누를 수 없는 버튼을 보여 주는 게 가장 나쁜 선택이다.
  bool _instagramInstalled = false;
  late Map<String, dynamic> _analysis;

  /// 이 화면의 결과가 저장된 기록 id. 업로드 직후 열리면 라우트로는 오지 않고
  /// 전역 상태에서 알게 된다.
  int? _recordId;

  /// 오류 화면의 '다시 시도'가 되풀이할 동작 (열기 또는 다시 분석).
  late Future<void> Function() _retry = _open;

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    _analysis = jsonDecode(widget.analysisJson) as Map<String, dynamic>;
    _recordId = widget.recordId;

    InstagramShareService().isInstalled().then((installed) {
      if (mounted) setState(() => _instagramInstalled = installed);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(transformProvider);
      // 전역 상태의 결과는 이 사진의 것일 때만 재사용한다. 히스토리/홈에서
      // 다른 사진으로 들어오면 이전 사진의 After가 남아 있을 수 있다.
      final belongs =
          state.belongsTo(widget.imagePath, recordId: widget.recordId);
      final hasResultForThisImage = belongs &&
          state.transformedImageBytes != null &&
          (state.status == TransformStatus.ready ||
              state.status == TransformStatus.applyingManual ||
              state.status == TransformStatus.saving);
      if (belongs) _recordId ??= state.recordId;
      if (!hasResultForThisImage) {
        _open();
      }
      // 대표 사진 로드
      ref.read(transformProvider.notifier).loadReferenceImages();
    });
  }

  /// 화면을 처음 채운다. 기록에서 왔으면 저장된 변형 값으로 복원하고
  /// (AI 호출 없음), 그렇지 않으면 분석을 돌린다.
  Future<void> _open() async {
    final recordId = _recordId;
    if (recordId == null) return _runAnalysis();
    _retry = _open;
    final result = await ref
        .read(transformProvider.notifier)
        .openRecord(recordId, _imageFile);
    _applyResult(result);
  }

  /// 분석+변형을 (다시) 돌리고, 새 분석 결과로 하단 분석 섹션도 갱신한다.
  /// 기록에 묶인 화면이면 새 기록을 만들지 않고 그 기록을 갱신한다.
  Future<void> _runAnalysis() async {
    _retry = _runAnalysis;
    final result = await ref
        .read(transformProvider.notifier)
        .analyzeAndTransform(_imageFile, recordId: _recordId);
    _applyResult(result);
  }

  void _applyResult(
      ({String analysisJson, String imagePath, int recordId})? result) {
    if (result == null || !mounted) return;
    _recordId = result.recordId;
    try {
      final analysis = jsonDecode(result.analysisJson);
      if (analysis is Map<String, dynamic>) {
        setState(() => _analysis = analysis);
      }
    } catch (_) {
      // 분석 JSON이 깨졌으면 기존 분석 섹션을 그대로 둔다
    }
  }

  Future<void> _onSave() async {
    final path =
        await ref.read(transformProvider.notifier).saveTransformedImage(_imageFile);
    if (!mounted) return;
    if (path != null) {
      showInstaToast(context, '\uBCC0\uD615\uB41C \uC0AC\uC9C4\uC774 \uC800\uC7A5\uB418\uC5C8\uC2B5\uB2C8\uB2E4',
          icon: Icons.check_circle_outline);
    } else {
      // 실패 시 provider는 ready + errorMessage로 돌아가는데, 화면은 error
      // 상태에서만 메시지를 그려 아무 반응이 없던 문제
      showInstaToast(
        context,
        ref.read(transformProvider).errorMessage ??
            '\uC0AC\uC9C4\uC744 \uC800\uC7A5\uD558\uC9C0 \uBABB\uD588\uC5B4\uC694',
        isError: true,
      );
    }
  }

  /// 변형 결과를 인스타그램으로 넘긴다.
  ///
  /// 저장 경로와 같은 파이프라인을 다시 태워 최종 화질로 만든 뒤 넘긴다 —
  /// 미리보기 바이트는 사용자가 슬라이더를 만졌을 때 최신이 아닐 수 있다.
  Future<void> _onShareToInstagram({required bool story}) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await ref
          .read(transformProvider.notifier)
          .renderForExport(_imageFile);
      if (bytes == null) {
        if (mounted) {
          showInstaToast(context, '\uC0AC\uC9C4\uC744 \uC900\uBE44\uD558\uC9C0 \uBABB\uD588\uC5B4\uC694', isError: true);
        }
        return;
      }

      final service = InstagramShareService();
      final result = story
          ? await service.shareToStory(bytes)
          : await service.shareToFeed(bytes);
      if (!mounted) return;

      switch (result) {
        case InstagramShareResult.opened:
          break; // 인스타그램으로 넘어갔다 — 토스트는 방해만 된다
        case InstagramShareResult.notInstalled:
          setState(() => _instagramInstalled = false);
          await _saveInsteadOfSharing('인스타그램이 없어 갤러리에 저장했어요');
        case InstagramShareResult.failed:
          await _saveInsteadOfSharing('인스타그램을 열지 못해 갤러리에 저장했어요');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// 공유가 안 될 때의 퇴로. 사진을 잃지 않도록 갤러리에 남긴다.
  Future<void> _saveInsteadOfSharing(String message) async {
    final path =
        await ref.read(transformProvider.notifier).saveTransformedImage(_imageFile);
    if (!mounted) return;
    if (path != null) {
      showInstaToast(context, message, icon: Icons.download_done_outlined);
    } else {
      showInstaToast(context, '\uC0AC\uC9C4\uC744 \uC800\uC7A5\uD558\uC9C0 \uBABB\uD588\uC5B4\uC694', isError: true);
    }
  }

  Future<void> _onReanalyze() async {
    final confirmed = await showInstaConfirm(
      context,
      title: '\uB2E4\uC2DC \uBD84\uC11D',
      message: '\uD604\uC7AC \uBCC0\uD615 \uACB0\uACFC\uB97C \uBC84\uB9AC\uACE0 \uB2E4\uC2DC \uBD84\uC11D\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
      confirmLabel: '\uB2E4\uC2DC \uBD84\uC11D',
    );
    if (confirmed && mounted) {
      await _runAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transformState = ref.watch(transformProvider);
    // 다른 사진의 결과가 남아 있으면 첫 프레임부터 로딩으로 보여 준다
    // (다음 프레임에 initState가 이 사진의 분석을 시작한다).
    final isLoading =
        transformState.status == TransformStatus.loadingAutoTransform ||
            !transformState.belongsTo(widget.imagePath, recordId: _recordId);
    final isSaving = transformState.status == TransformStatus.saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\uBD84\uC11D & \uBCC0\uD615',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
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
          // 다시 분석 버튼
          if (transformState.transformedImageBytes != null && !isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '\uB2E4\uC2DC \uBD84\uC11D',
              onPressed: _onReanalyze,
            ),
          // 인스타그램 편집 화면의 그래디언트 완료 액션
          if (transformState.transformedImageBytes != null && !isLoading)
            GestureDetector(
              onTap: isSaving ? null : _onSave,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: Center(
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const GradientText(
                          '\uC800\uC7A5',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transformState.restoring &&
                            transformState.status ==
                                TransformStatus.loadingAutoTransform
                        // 변형 결과를 불러오는 중...
                        ? '\uBCC0\uD615 \uACB0\uACFC\uB97C \uBD88\uB7EC\uC624\uB294 \uC911...'
                        // 서버 작업 단계가 오면 그 문구 (대기 중 / 분석 / 보정 적용)
                        : transformState.analysisProgress?.stage.message ??
                            'AI\uAC00 \uC0AC\uC9C4\uC744 \uBD84\uC11D\uD558\uACE0 \uBCC0\uD615\uD558\uB294 \uC911...',
                    style: TextStyle(fontSize: 14, color: context.instaSecondary),
                  ),
                  if (!transformState.restoring &&
                      transformState.analysisProgress?.resumable == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      // 앱을 잠시 나가도 분석은 계속돼요
                      '\uC571\uC744 \uC7A0\uC2DC \uB098\uAC00\uB3C4 \uBD84\uC11D\uC740 \uACC4\uC18D\uB3FC\uC694',
                      style: TextStyle(fontSize: 12, color: context.instaSecondary),
                    ),
                  ],
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
                          transformState.errorMessage ?? '\uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 160,
                          child: InstaSecondaryButton(
                            label: '\uB2E4\uC2DC \uC2DC\uB3C4',
                            icon: Icons.refresh,
                            onPressed: () => _retry(),
                          ),
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
                      child: _BeforeAfterTabView(
                        originalImage: _imageFile,
                        transformedBytes:
                            transformState.transformedImageBytes,
                        isApplying: transformState.status ==
                            TransformStatus.applyingManual,
                      ),
                    ),

                    // ── 2. 인스타그램으로 공유 ──
                    if (transformState.transformedImageBytes != null)
                      _ShareRow(
                        busy: _sharing,
                        instagramInstalled: _instagramInstalled,
                        onStory: () => _onShareToInstagram(story: true),
                        onFeed: () => _onShareToInstagram(story: false),
                        onSave: _onSave,
                      ),

                    // ── 2-1. 크롭 제안 (서버는 구도를 자동으로 바꾸지 않는다) ──
                    if (transformState.transformedImageBytes != null &&
                        transformState.hasCropSuggestion)
                      _CropSuggestionRow(
                        applied: transformState.cropSuggestionApplied,
                        busy: transformState.status ==
                                TransformStatus.applyingManual ||
                            transformState.status == TransformStatus.saving,
                        onToggle: () => ref
                            .read(transformProvider.notifier)
                            .toggleSuggestedCrop(_imageFile),
                      ),

                    // ── 3. 적용된 변형 요약 ──
                    _AppliedTransformsSummary(
                      params: transformState.params,
                      comment: transformState.paramsComment,
                      styleName: transformState.appliedStyleName,
                    ),

                    const SizedBox(height: 16),
                    const InstaHairline(indent: 20, endIndent: 20),
                    const SizedBox(height: 16),

                    // ── 7. 분석 결과 ──
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
  final Widget? trailing;
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.instaPrimaryText),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.instaPrimaryText,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── 적용된 변형 요약 ──

class _AppliedTransformsSummary extends StatelessWidget {
  final TransformParams params;

  /// 서버가 계산한 보정 이유 한 문장.
  final String? comment;

  /// 설정에서 고른 보정 스타일 이름 (자동이면 null).
  final String? styleName;

  const _AppliedTransformsSummary({
    required this.params,
    this.comment,
    this.styleName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_TransformItem>[];

    // 색감 보정
    if (params.brightness.abs() >= 0.01) {
      items.add(_TransformItem(Icons.brightness_6_outlined, '\uBC1D\uAE30', params.brightness));
    }
    if (params.contrast.abs() >= 0.01) {
      items.add(_TransformItem(Icons.contrast_outlined, '\uB300\uBE44', params.contrast));
    }
    if (params.clarity.abs() >= 0.01) {
      items.add(_TransformItem(Icons.hdr_strong_outlined, '\uC120\uBA85\uAC10', params.clarity));
    }
    if (params.dehaze.abs() >= 0.01) {
      items.add(_TransformItem(Icons.cloud_off_outlined, '\uC548\uAC1C \uC81C\uAC70', params.dehaze));
    }
    if (params.highlights.abs() >= 0.01) {
      items.add(_TransformItem(Icons.wb_sunny_outlined, '\uD558\uC774\uB77C\uC774\uD2B8', params.highlights));
    }
    if (params.shadows.abs() >= 0.01) {
      items.add(_TransformItem(Icons.nights_stay_outlined, '\uC250\uB3C4\uC6B0', params.shadows));
    }
    if (params.saturation.abs() >= 0.01) {
      items.add(_TransformItem(Icons.palette_outlined, '\uCC44\uB3C4', params.saturation));
    }
    if (params.temperature.abs() >= 0.01) {
      items.add(_TransformItem(Icons.thermostat_outlined, '\uC0C9\uC628\uB3C4', params.temperature));
    }

    // 디테일
    if (params.sharpness.abs() >= 0.01) {
      items.add(_TransformItem(Icons.deblur_outlined, '\uC120\uBA85\uB3C4', params.sharpness));
    }
    if (params.grain >= 0.01) {
      items.add(_TransformItem(Icons.grain_outlined, '\uADF8\uB808\uC778', params.grain));
    }
    if (params.vignette.abs() >= 0.01) {
      items.add(_TransformItem(Icons.vignette_outlined, '\uBE44\uB124\uD305', params.vignette));
    }

    // 촬영 결함 교정
    if (params.autoWb >= 0.01) {
      items.add(_TransformItem(Icons.wb_auto_outlined, '\uD654\uC774\uD2B8\uBC38\uB7F0\uC2A4', params.autoWb));
    }
    if (params.denoise >= 0.01) {
      items.add(_TransformItem(Icons.blur_on, '\uB178\uC774\uC988 \uC81C\uAC70', params.denoise));
    }
    if (params.backgroundBlur >= 0.01) {
      items.add(_TransformItem(Icons.lens_blur, '\uBC30\uACBD \uD750\uB9BC', params.backgroundBlur));
    }

    // 피부 보정
    if (params.blemishRemoval >= 0.01) {
      items.add(_TransformItem(Icons.auto_fix_high_outlined, '\uC7A1\uD2F0 \uC81C\uAC70', params.blemishRemoval));
    }
    if (params.skinSmoothing >= 0.01) {
      items.add(_TransformItem(Icons.face_outlined, '\uD53C\uBD80 \uBCF4\uC815', params.skinSmoothing));
    }

    // 톤 커브
    if (params.toneCurvePreset != 'linear' && params.toneCurveStrength >= 0.01) {
      items.add(_TransformItem(Icons.show_chart, '\uD1A4 \uCEE4\uBE0C', params.toneCurveStrength,
          label2: _toneCurveLabel(params.toneCurvePreset)));
    }

    // 스플릿 토닝
    if (params.splitShadowStrength >= 0.01) {
      items.add(_TransformItem(Icons.color_lens_outlined, '\uC250\uB3C4\uC6B0 \uC0C9\uC870', params.splitShadowStrength));
    }
    if (params.splitHighlightStrength >= 0.01) {
      items.add(_TransformItem(Icons.color_lens_outlined, '\uD558\uC774\uB77C\uC774\uD2B8 \uC0C9\uC870', params.splitHighlightStrength));
    }

    // 얼굴/체형
    if (params.faceSlim >= 0.01) {
      items.add(_TransformItem(Icons.face_retouching_natural, '\uC5BC\uAD74 \uCD95\uC18C', params.faceSlim));
    }
    if (params.jawSharpen >= 0.01) {
      items.add(_TransformItem(Icons.architecture_outlined, '\uD131\uC120', params.jawSharpen));
    }
    if (params.eyeEnlarge >= 0.01) {
      items.add(_TransformItem(Icons.visibility_outlined, '\uB208 \uD655\uB300', params.eyeEnlarge));
    }
    if (params.legStretch >= 0.01) {
      items.add(_TransformItem(Icons.straighten_outlined, '\uB2E4\uB9AC \uB298\uB9AC\uAE30', params.legStretch));
    }
    if (params.shoulderWidth.abs() >= 0.01) {
      items.add(_TransformItem(Icons.open_in_full_outlined, '\uC5B4\uAE68 \uB108\uBE44', params.shoulderWidth));
    }
    if (params.waistSlim >= 0.01) {
      items.add(_TransformItem(Icons.compress_outlined, '\uD5C8\uB9AC \uB77C\uC778', params.waistSlim));
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.auto_awesome_outlined,
            title: '\uC801\uC6A9\uB41C \uBCC0\uD615',
            trailing: styleName == null
                ? null
                : Text(
                    '\uBCF4\uC815 \uC2A4\uD0C0\uC77C \u00B7 $styleName',
                    style: AppTypography.meta
                        .copyWith(color: context.instaSecondary),
                  ),
          ),
          if (comment != null && comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                comment!,
                style: AppTypography.secondary
                    .copyWith(color: context.instaSecondary),
              ),
            )
          else
            const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              final display = (item.value * 100).round();
              final valueStr = item.label2 ??
                  (display > 0 ? '+$display' : '$display');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${item.name} $valueStr',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _toneCurveLabel(String preset) => switch (preset) {
        's_curve' => 'S\uCEE4\uBE0C',
        'film' => '\uD544\uB984',
        'fade' => '\uD398\uC774\uB4DC',
        'high_contrast' => '\uACE0\uB300\uBE44',
        'bright' => '\uBC1D\uAC8C',
        _ => preset,
      };
}

class _TransformItem {
  final IconData icon;
  final String name;
  final double value;
  final String? label2;
  const _TransformItem(this.icon, this.name, this.value, {this.label2});
}

// ── 분석 결과 섹션 ──

class _AnalysisSection extends StatelessWidget {
  final Map<String, dynamic> analysis;
  const _AnalysisSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    PhotoAnalysisResponse? parsed;
    try {
      parsed = PhotoAnalysisResponse.fromJson(analysis);
    } catch (_) {}

    if (parsed != null) {
      return _ParsedAnalysis(analysis: parsed);
    }
    return _RawAnalysis(analysis: analysis);
  }
}

class _ParsedAnalysis extends StatelessWidget {
  final PhotoAnalysisResponse analysis;
  const _ParsedAnalysis({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.analytics_outlined, title: '\uBD84\uC11D'),
          const SizedBox(height: 4),

          // 점수 + 톤 리포트
          ToneReportCard(toneReport: analysis.toneReport),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.analytics_outlined, title: '\uBD84\uC11D'),
          const SizedBox(height: 4),
          Row(
            children: [
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
                '\uD53C\uB4DC \uBBF8\uB9AC\uBCF4\uAE30',
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
              Expanded(child: _gridCell(context, ref0, '\uB300\uD45C 1')),
              const SizedBox(width: 2),
              Expanded(child: _gridCell(context, transformedImage, '\uBCC0\uD615')),
              const SizedBox(width: 2),
              Expanded(child: _gridCell(context, ref1, '\uB300\uD45C 2')),
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

// ── Before/After 탭 비교 뷰 ──

class _BeforeAfterTabView extends StatefulWidget {
  final File originalImage;
  final Uint8List? transformedBytes;
  final bool isApplying;

  const _BeforeAfterTabView({
    required this.originalImage,
    required this.transformedBytes,
    required this.isApplying,
  });

  @override
  State<_BeforeAfterTabView> createState() => _BeforeAfterTabViewState();
}

class _BeforeAfterTabViewState extends State<_BeforeAfterTabView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// 첫 진입 힌트 표시 여부 (페이드 애니메이션을 위해 별도 opacity 관리).
  double _hintOpacity = 0.0;
  bool _hintActive = false;

  static const _hintShownKey = 'before_after_tab_hint_shown';

  @override
  void initState() {
    super.initState();
    // 변형 결과가 있으면 After 탭부터 보여준다.
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.transformedBytes != null ? 1 : 0,
    );
    _tabController.addListener(_onTabChanged);
    _checkFirstVisitHint();
  }

  @override
  void didUpdateWidget(covariant _BeforeAfterTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 변형이 막 완료되면 자동으로 After 탭으로 이동
    if (oldWidget.transformedBytes == null && widget.transformedBytes != null) {
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// 탭/스와이프로 전환하면 힌트를 즉시 감춘다.
  void _onTabChanged() {
    if (_hintActive) {
      setState(() {
        _hintOpacity = 0.0;
        _hintActive = false;
      });
    }
  }

  Future<void> _checkFirstVisitHint() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_hintShownKey) ?? false;
    if (!shown && mounted) {
      setState(() {
        _hintActive = true;
        _hintOpacity = 1.0;
      });
      await prefs.setBool(_hintShownKey, true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _hintActive) {
          setState(() => _hintOpacity = 0.0);
          // 페이드아웃 완료 후 위젯 제거
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _hintActive = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTransformed = widget.transformedBytes != null;

    // 변형 결과가 없으면 원본만 표시 (비교할 대상이 없음)
    if (!hasTransformed) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.file(widget.originalImage, fit: BoxFit.contain),
          ),
          if (widget.isApplying) const _ApplyingSpinner(),
        ],
      );
    }

    return Column(
      children: [
        _BeforeAfterTabBar(controller: _tabController),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Image.file(
                      widget.originalImage,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                    Image.memory(
                      widget.transformedBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ],
                ),
              ),
              // 첫 진입 힌트 오버레이
              if (_hintActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hintOpacity,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swipe,
                                    size: 36,
                                    color: Colors.white.withValues(alpha: 0.9)),
                                const SizedBox(height: 8),
                                Text(
                                  'Before / After 탭으로 전환',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '좌우로 스와이프해도 넘길 수 있어요',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.isApplying) const _ApplyingSpinner(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Before/After 세그먼트 탭바.
class _BeforeAfterTabBar extends StatelessWidget {
  final TabController controller;
  const _BeforeAfterTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(999);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: radius,
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            gradient: AppColors.instagramGradient,
            borderRadius: radius,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          splashBorderRadius: radius,
          labelColor: Colors.white,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(height: 36, text: 'Before'),
            Tab(height: 36, text: 'After'),
          ],
        ),
      ),
    );
  }
}

class _ApplyingSpinner extends StatelessWidget {
  const _ApplyingSpinner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      ),
    );
  }
}

/// 결과 공유 버튼.
///
/// 인스타그램이 있으면 스토리·피드로 직행하는 버튼 두 개를, 없으면
/// 갤러리 저장 버튼 하나를 보여 준다. 누를 수 없는 버튼은 내보이지 않는다.
/// AI가 제안한 구도로 자르기 / 원래 구도로 되돌리기.
///
/// 크롭은 사용자가 잡은 구도를 바꾸는 편집이라 자동으로 적용하지 않고
/// 여기서 고르게 한다. 켠 상태는 기록에도 남아 다시 열거나 저장할 때 같다.
class _CropSuggestionRow extends StatelessWidget {
  final bool applied;
  final bool busy;
  final VoidCallback onToggle;

  const _CropSuggestionRow({
    required this.applied,
    required this.busy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Icon(Icons.crop_outlined, size: 16, color: context.instaSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              applied
                  ? '\uCD94\uCC9C \uAD6C\uB3C4\uB85C \uC790\uB978 \uC0AC\uC9C4\uC774\uC5D0\uC694'
                  : '\uCD94\uCC9C \uAD6C\uB3C4\uAC00 \uC788\uC5B4\uC694',
              style: TextStyle(fontSize: 13, color: context.instaSecondary),
            ),
          ),
          InstaPill(
            label: applied
                ? '\uC6D0\uB798 \uAD6C\uB3C4\uB85C'
                : '\uCD94\uCC9C \uAD6C\uB3C4\uB85C \uC790\uB974\uAE30',
            selected: applied,
            dense: true,
            onTap: busy ? () {} : onToggle,
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  final bool busy;
  final bool instagramInstalled;
  final VoidCallback onStory;
  final VoidCallback onFeed;
  final VoidCallback onSave;

  const _ShareRow({
    required this.busy,
    required this.instagramInstalled,
    required this.onStory,
    required this.onFeed,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: instagramInstalled
          ? Row(
              children: [
                Expanded(
                  child: InstagramGradientButton(
                    height: 44,
                    isLoading: busy,
                    onPressed: busy ? null : onStory,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '스토리에 공유',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InstaSecondaryButton(
                    label: '피드에 공유',
                    icon: Icons.grid_on_outlined,
                    onPressed: busy ? null : onFeed,
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: InstaSecondaryButton(
                label: '갤러리에 저장',
                icon: Icons.download_outlined,
                onPressed: busy ? null : onSave,
              ),
            ),
    );
  }
}
