import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../data/analysis_repository.dart';
import 'analysis_provider.dart';

enum TransformStatus {
  idle,
  loadingAutoTransform,
  ready,
  applyingManual,
  saving,
  error,
}

class TransformParams {
  final double brightness;
  final double contrast;
  final double clarity;
  final double dehaze;
  final double highlights;
  final double shadows;
  final double saturation;
  final double temperature;
  final double blemishRemoval;
  final double skinSmoothing;
  final double vignette;
  final double sharpness;
  final double grain;
  final String toneCurvePreset;
  final double toneCurveStrength;
  final double splitShadowHue;
  final double splitShadowStrength;
  final double splitHighlightHue;
  final double splitHighlightStrength;
  final Map<String, Map<String, double>>? hslAdjust;
  // ── 얼굴/체형 보정 ──
  final double faceSlim;
  final double jawSharpen;
  final double eyeEnlarge;
  final double legStretch;
  final double shoulderWidth;
  final double waistSlim;

  const TransformParams({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.clarity = 0.0,
    this.dehaze = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.saturation = 0.0,
    this.temperature = 0.0,
    this.blemishRemoval = 0.0,
    this.skinSmoothing = 0.0,
    this.vignette = 0.0,
    this.sharpness = 0.0,
    this.grain = 0.0,
    this.toneCurvePreset = 'linear',
    this.toneCurveStrength = 0.0,
    this.splitShadowHue = 0.0,
    this.splitShadowStrength = 0.0,
    this.splitHighlightHue = 0.0,
    this.splitHighlightStrength = 0.0,
    this.hslAdjust,
    this.faceSlim = 0.0,
    this.jawSharpen = 0.0,
    this.eyeEnlarge = 0.0,
    this.legStretch = 0.0,
    this.shoulderWidth = 0.0,
    this.waistSlim = 0.0,
  });

  TransformParams copyWith({
    double? brightness,
    double? contrast,
    double? clarity,
    double? dehaze,
    double? highlights,
    double? shadows,
    double? saturation,
    double? temperature,
    double? blemishRemoval,
    double? skinSmoothing,
    double? vignette,
    double? sharpness,
    double? grain,
    String? toneCurvePreset,
    double? toneCurveStrength,
    double? splitShadowHue,
    double? splitShadowStrength,
    double? splitHighlightHue,
    double? splitHighlightStrength,
    Map<String, Map<String, double>>? hslAdjust,
    double? faceSlim,
    double? jawSharpen,
    double? eyeEnlarge,
    double? legStretch,
    double? shoulderWidth,
    double? waistSlim,
  }) {
    return TransformParams(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      clarity: clarity ?? this.clarity,
      dehaze: dehaze ?? this.dehaze,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      saturation: saturation ?? this.saturation,
      temperature: temperature ?? this.temperature,
      blemishRemoval: blemishRemoval ?? this.blemishRemoval,
      skinSmoothing: skinSmoothing ?? this.skinSmoothing,
      vignette: vignette ?? this.vignette,
      sharpness: sharpness ?? this.sharpness,
      grain: grain ?? this.grain,
      toneCurvePreset: toneCurvePreset ?? this.toneCurvePreset,
      toneCurveStrength: toneCurveStrength ?? this.toneCurveStrength,
      splitShadowHue: splitShadowHue ?? this.splitShadowHue,
      splitShadowStrength: splitShadowStrength ?? this.splitShadowStrength,
      splitHighlightHue: splitHighlightHue ?? this.splitHighlightHue,
      splitHighlightStrength: splitHighlightStrength ?? this.splitHighlightStrength,
      hslAdjust: hslAdjust ?? this.hslAdjust,
      faceSlim: faceSlim ?? this.faceSlim,
      jawSharpen: jawSharpen ?? this.jawSharpen,
      eyeEnlarge: eyeEnlarge ?? this.eyeEnlarge,
      legStretch: legStretch ?? this.legStretch,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      waistSlim: waistSlim ?? this.waistSlim,
    );
  }

  factory TransformParams.fromJson(Map<String, dynamic> json) {
    // toneCurve는 중첩 객체 또는 평탄화된 키로 올 수 있음
    String tcPreset = 'linear';
    double tcStrength = 0.0;
    final toneCurve = json['toneCurve'];
    if (toneCurve is Map<String, dynamic>) {
      tcPreset = (toneCurve['preset'] as String?) ?? 'linear';
      tcStrength = (toneCurve['strength'] as num?)?.toDouble() ?? 0.0;
    } else {
      tcPreset = (json['tone_curve_preset'] as String?) ?? 'linear';
      tcStrength = (json['tone_curve_strength'] as num?)?.toDouble() ?? 0.0;
    }

    // splitToning도 중첩 객체 또는 평탄화된 키로 올 수 있음
    double shHue = 0.0, shStr = 0.0, hlHue = 0.0, hlStr = 0.0;
    final splitToning = json['splitToning'];
    if (splitToning is Map<String, dynamic>) {
      final shadow = splitToning['shadow'];
      final highlight = splitToning['highlight'];
      if (shadow is Map<String, dynamic>) {
        shHue = (shadow['hue'] as num?)?.toDouble() ?? 0.0;
        shStr = (shadow['strength'] as num?)?.toDouble() ?? 0.0;
      }
      if (highlight is Map<String, dynamic>) {
        hlHue = (highlight['hue'] as num?)?.toDouble() ?? 0.0;
        hlStr = (highlight['strength'] as num?)?.toDouble() ?? 0.0;
      }
    } else {
      shHue = (json['split_shadow_hue'] as num?)?.toDouble() ?? 0.0;
      shStr = (json['split_shadow_strength'] as num?)?.toDouble() ?? 0.0;
      hlHue = (json['split_highlight_hue'] as num?)?.toDouble() ?? 0.0;
      hlStr = (json['split_highlight_strength'] as num?)?.toDouble() ?? 0.0;
    }

    // hslAdjust 파싱
    Map<String, Map<String, double>>? hslParsed;
    final hslRaw = json['hslAdjust'] ?? json['hsl_adjust'];
    if (hslRaw is Map<String, dynamic>) {
      final parsed = <String, Map<String, double>>{};
      for (final entry in hslRaw.entries) {
        if (entry.value is Map<String, dynamic>) {
          final adj = <String, double>{};
          for (final k in ['hue', 'saturation', 'lightness']) {
            adj[k] = (entry.value[k] as num?)?.toDouble() ?? 0.0;
          }
          if (adj.values.any((v) => v.abs() >= 0.01)) {
            parsed[entry.key] = adj;
          }
        }
      }
      if (parsed.isNotEmpty) hslParsed = parsed;
    }

    // reshapeParams 파싱
    final reshape = json['reshapeParams'] as Map<String, dynamic>?;
    double faceSlim = 0.0, jawSharpen = 0.0, eyeEnlarge = 0.0;
    double legStretch = 0.0, shoulderWidth = 0.0, waistSlim = 0.0;
    if (reshape != null) {
      faceSlim = (reshape['face_slim'] as num?)?.toDouble() ?? 0.0;
      jawSharpen = (reshape['jaw_sharpen'] as num?)?.toDouble() ?? 0.0;
      eyeEnlarge = (reshape['eye_enlarge'] as num?)?.toDouble() ?? 0.0;
      legStretch = (reshape['leg_stretch'] as num?)?.toDouble() ?? 0.0;
      shoulderWidth = (reshape['shoulder_width'] as num?)?.toDouble() ?? 0.0;
      waistSlim = (reshape['waist_slim'] as num?)?.toDouble() ?? 0.0;
    } else {
      // 평탄화된 키로도 올 수 있음
      faceSlim = (json['face_slim'] as num?)?.toDouble() ?? 0.0;
      jawSharpen = (json['jaw_sharpen'] as num?)?.toDouble() ?? 0.0;
      eyeEnlarge = (json['eye_enlarge'] as num?)?.toDouble() ?? 0.0;
      legStretch = (json['leg_stretch'] as num?)?.toDouble() ?? 0.0;
      shoulderWidth = (json['shoulder_width'] as num?)?.toDouble() ?? 0.0;
      waistSlim = (json['waist_slim'] as num?)?.toDouble() ?? 0.0;
    }

    return TransformParams(
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
      clarity: (json['clarity'] as num?)?.toDouble() ?? 0.0,
      dehaze: (json['dehaze'] as num?)?.toDouble() ?? 0.0,
      highlights: (json['highlights'] as num?)?.toDouble() ?? 0.0,
      shadows: (json['shadows'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      blemishRemoval: (json['blemish_removal'] as num?)?.toDouble() ?? 0.0,
      skinSmoothing: (json['skin_smoothing'] as num?)?.toDouble() ?? 0.0,
      vignette: (json['vignette'] as num?)?.toDouble() ?? 0.0,
      sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0.0,
      grain: (json['grain'] as num?)?.toDouble() ?? 0.0,
      toneCurvePreset: tcPreset,
      toneCurveStrength: tcStrength,
      splitShadowHue: shHue,
      splitShadowStrength: shStr,
      splitHighlightHue: hlHue,
      splitHighlightStrength: hlStr,
      hslAdjust: hslParsed,
      faceSlim: faceSlim,
      jawSharpen: jawSharpen,
      eyeEnlarge: eyeEnlarge,
      legStretch: legStretch,
      shoulderWidth: shoulderWidth,
      waistSlim: waistSlim,
    );
  }

  Map<String, double> toMap() => {
        'brightness': brightness,
        'contrast': contrast,
        'clarity': clarity,
        'dehaze': dehaze,
        'highlights': highlights,
        'shadows': shadows,
        'saturation': saturation,
        'temperature': temperature,
        'blemishRemoval': blemishRemoval,
        'skinSmoothing': skinSmoothing,
        'vignette': vignette,
        'sharpness': sharpness,
        'grain': grain,
        'toneCurveStrength': toneCurveStrength,
        'splitShadowStrength': splitShadowStrength,
        'splitHighlightStrength': splitHighlightStrength,
        'faceSlim': faceSlim,
        'jawSharpen': jawSharpen,
        'eyeEnlarge': eyeEnlarge,
        'legStretch': legStretch,
        'shoulderWidth': shoulderWidth,
        'waistSlim': waistSlim,
      };

  /// AI 추천값과 최종 사용값의 차이(delta) 계산
  /// toneCurveStrength만 포함 (preset은 delta 계산 불가)
  Map<String, double> deltaFrom(TransformParams other) {
    final thisMap = toMap();
    final otherMap = other.toMap();
    return {
      for (final key in thisMap.keys) key: thisMap[key]! - otherMap[key]!,
    };
  }
}

class TransformState {
  final TransformStatus status;
  final TransformParams params;
  final TransformParams? originalParams; // AI 추천 초기값 (피드백 delta 계산용)
  final Uint8List? transformedImageBytes;
  final List<Uint8List>? referenceImages; // 대표 사진 캐시 (base64 디코딩)
  final String? errorMessage;

  const TransformState({
    this.status = TransformStatus.idle,
    this.params = const TransformParams(),
    this.originalParams,
    this.transformedImageBytes,
    this.referenceImages,
    this.errorMessage,
  });

  TransformState copyWith({
    TransformStatus? status,
    TransformParams? params,
    TransformParams? originalParams,
    Uint8List? transformedImageBytes,
    List<Uint8List>? referenceImages,
    String? errorMessage,
  }) {
    return TransformState(
      status: status ?? this.status,
      params: params ?? this.params,
      originalParams: originalParams ?? this.originalParams,
      transformedImageBytes: transformedImageBytes ?? this.transformedImageBytes,
      referenceImages: referenceImages ?? this.referenceImages,
      errorMessage: errorMessage,
    );
  }
}

class TransformNotifier extends Notifier<TransformState> {
  @override
  TransformState build() => const TransformState();

  /// 슬라이더 UI 반응성을 위해 params만 즉시 업데이트 (서버 호출 없음)
  void updateParamsOnly(TransformParams params) {
    state = state.copyWith(params: params);
  }

  /// 대표 사진 로드 (변형 화면 진입 시 호출)
  Future<void> loadReferenceImages() async {
    try {
      String userId = '';
      try {
        final authState = ref.read(instagramAuthProvider);
        userId = authState.userId ?? '';
      } catch (_) {}

      if (userId.isEmpty) return;

      // 이미 캐시되어 있으면 스킵
      if (state.referenceImages != null && state.referenceImages!.isNotEmpty) {
        return;
      }

      final repo = ref.read(analysisRepositoryProvider);
      final images = await repo.fetchReferenceImages(userId);

      if (images.isNotEmpty) {
        final decoded = images.map((b64) => base64Decode(b64)).toList();
        state = state.copyWith(referenceImages: decoded);
        developer.log('Loaded ${decoded.length} reference images',
            name: 'Transform');
      }
    } catch (e) {
      developer.log('loadReferenceImages failed: $e', name: 'Transform');
    }
  }

  /// 분석 + 변형 통합 — 한 번의 API 호출로 분석과 변형을 동시에 수행
  Future<({String analysisJson, String imagePath})?> analyzeAndTransform(File imageFile) async {
    state = state.copyWith(
      status: TransformStatus.loadingAutoTransform,
      errorMessage: null,
    );

    try {
      final repo = ref.read(analysisRepositoryProvider);
      final styleProfile = ref.read(userStyleProfileProvider);

      // Instagram userId 조회 (대표 사진 레퍼런스용)
      String userId = '';
      try {
        final authState = ref.read(instagramAuthProvider);
        userId = authState.userId ?? '';
      } catch (_) {}

      final result = await repo.analyzeAndTransform(
        imageFile: imageFile,
        styleProfile: styleProfile,
        userId: userId,
      );

      final imageB64 = result.fullResult['image_base64'] as String?;
      final paramsMap = result.fullResult['params'] as Map<String, dynamic>?;

      if (imageB64 == null) {
        state = state.copyWith(
          status: TransformStatus.error,
          errorMessage: '변형된 이미지를 받지 못했습니다',
        );
        return null;
      }

      final aiParams = paramsMap != null
          ? TransformParams.fromJson(paramsMap)
          : const TransformParams();

      state = state.copyWith(
        status: TransformStatus.ready,
        params: aiParams,
        originalParams: aiParams, // AI 추천 초기값 저장
        transformedImageBytes: base64Decode(imageB64),
      );

      return (analysisJson: result.analysisJson, imagePath: result.imagePath);
    } catch (e) {
      developer.log('analyzeAndTransform failed: $e', name: 'Transform');
      state = state.copyWith(
        status: TransformStatus.error,
        errorMessage: '분석 및 변형 실패: $e',
      );
    }
  }

  /// 슬라이더 변경 시 수동 변형
  Future<void> applyManual(File imageFile, TransformParams params) async {
    state = state.copyWith(
      status: TransformStatus.applyingManual,
      params: params,
      errorMessage: null,
    );

    try {
      final repo = ref.read(analysisRepositoryProvider);

      final result = await repo.applyTransform(
        imageFile: imageFile,
        brightness: params.brightness,
        contrast: params.contrast,
        clarity: params.clarity,
        dehaze: params.dehaze,
        highlights: params.highlights,
        shadows: params.shadows,
        saturation: params.saturation,
        temperature: params.temperature,
        blemishRemoval: params.blemishRemoval,
        skinSmoothing: params.skinSmoothing,
        vignette: params.vignette,
        sharpness: params.sharpness,
        grain: params.grain,
        toneCurvePreset: params.toneCurvePreset,
        toneCurveStrength: params.toneCurveStrength,
        splitShadowHue: params.splitShadowHue,
        splitShadowStrength: params.splitShadowStrength,
        splitHighlightHue: params.splitHighlightHue,
        splitHighlightStrength: params.splitHighlightStrength,
        hslAdjust: params.hslAdjust,
        faceSlim: params.faceSlim,
        jawSharpen: params.jawSharpen,
        eyeEnlarge: params.eyeEnlarge,
        legStretch: params.legStretch,
        shoulderWidth: params.shoulderWidth,
        waistSlim: params.waistSlim,
      );

      final imageB64 = result['image_base64'] as String?;

      if (imageB64 == null) {
        state = state.copyWith(status: TransformStatus.ready);
        return;
      }

      state = state.copyWith(
        status: TransformStatus.ready,
        transformedImageBytes: base64Decode(imageB64),
      );
    } catch (e) {
      developer.log('applyManual failed: $e', name: 'Transform');
      state = state.copyWith(
        status: TransformStatus.ready,
        errorMessage: '변형 적용 실패: $e',
      );
    }
  }

  /// 변형된 이미지를 갤러리에 저장 + 피드백 기록
  Future<String?> saveTransformedImage() async {
    final bytes = state.transformedImageBytes;
    if (bytes == null) return null;

    state = state.copyWith(status: TransformStatus.saving);

    try {
      // 임시 파일로 먼저 저장 (Gal은 파일 경로 필요)
      final tempDir = await getTemporaryDirectory();
      final savePath = p.join(
        tempDir.path,
        'transformed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(savePath).writeAsBytes(bytes);

      // 갤러리에 저장
      await Gal.putImage(savePath, album: 'Gamdo');

      // 임시 파일 정리
      await File(savePath).delete();

      // 피드백 저장 (슬라이더 조정 delta)
      await _saveFeedback();

      state = state.copyWith(status: TransformStatus.ready);
      developer.log('Saved transformed image to gallery', name: 'Transform');
      return savePath;
    } catch (e) {
      developer.log('saveTransformedImage failed: $e', name: 'Transform');
      state = state.copyWith(
        status: TransformStatus.ready,
        errorMessage: '저장 실패: $e',
      );
      return null;
    }
  }

  /// 사용자 피드백(delta)을 Firebase에 저장하고 targetParams 업데이트
  Future<void> _saveFeedback() async {
    final originalParams = state.originalParams;
    if (originalParams == null) return;

    String userId = '';
    try {
      final authState = ref.read(instagramAuthProvider);
      userId = authState.userId ?? '';
    } catch (_) {}

    if (userId.isEmpty) return;

    try {
      final delta = state.params.deltaFrom(originalParams);

      // delta가 모두 0이면 피드백 저장 불필요
      final hasChange = delta.values.any((v) => v.abs() > 0.001);
      if (!hasChange) return;

      final firebaseService = ref.read(firebaseServiceProvider);

      // 1. delta 저장
      await firebaseService.saveFeedback(userId: userId, delta: delta);

      // 2. 누적 피드백 로드 및 평균 계산
      final history = await firebaseService.loadFeedbackHistory(userId);
      if (history.isEmpty) return;

      final avgDelta = <String, double>{};
      final allKeys = history.expand((m) => m.keys).toSet();
      for (final key in allKeys) {
        final values = history
            .where((m) => m.containsKey(key))
            .map((m) => m[key]!)
            .toList();
        avgDelta[key] = values.reduce((a, b) => a + b) / values.length;
      }

      // 3. targetParams 업데이트 (학습률 0.3)
      await firebaseService.updateTargetParams(
        userId: userId,
        avgDelta: avgDelta,
        learningRate: 0.3,
      );

      // 4. 인메모리 스타일 프로필의 targetParams도 업데이트
      final styleProfile = ref.read(userStyleProfileProvider);
      if (styleProfile != null) {
        final currentTarget =
            Map<String, dynamic>.from(styleProfile['targetParams'] ?? {});
        for (final entry in avgDelta.entries) {
          final oldVal = (currentTarget[entry.key] as num?)?.toDouble() ?? 0.0;
          currentTarget[entry.key] =
              (oldVal + 0.3 * entry.value).clamp(-1.0, 1.0);
        }
        styleProfile['targetParams'] = currentTarget;
        ref.read(userStyleProfileProvider.notifier).state = {...styleProfile};
      }

      developer.log('Feedback saved and targetParams updated',
          name: 'Transform');
    } catch (e) {
      developer.log('_saveFeedback failed: $e', name: 'Transform');
    }
  }
}

final transformProvider =
    NotifierProvider<TransformNotifier, TransformState>(() {
  return TransformNotifier();
});
