import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/providers/style_profile_provider.dart';
import '../../../../core/services/image_service.dart';
import '../../di/analysis_providers.dart';
import '../../domain/entities/analysis_job_progress.dart';
import '../../domain/entities/stored_transform.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../../domain/entities/transform_params.dart';

// Re-export TransformParams so existing consumers still see it here
export '../../domain/entities/transform_params.dart';

/// 피부 보정(잡티 제거·피부 스무딩)을 뺀 값.
///
/// 전역 값과 영역별 얼굴 값(regionParams.face)을 모두 0으로 만든다.
/// 서버가 `skin_retouch_enabled: false` 분석에서 하는 것과 같다.
({TransformParams params, Map<String, dynamic>? regionParams})
    withoutSkinRetouch(
  TransformParams params,
  Map<String, dynamic>? regionParams,
) {
  Map<String, dynamic>? region = regionParams;
  final face = regionParams?['face'];
  if (face is Map) {
    region = {
      ...regionParams!,
      'face': {
        ...Map<String, dynamic>.from(face),
        'skin_smoothing': 0.0,
        'blemish_removal': 0.0,
      },
    };
  }
  return (
    params: params.copyWith(skinSmoothing: 0.0, blemishRemoval: 0.0),
    regionParams: region,
  );
}

enum TransformStatus {
  idle,
  loadingAutoTransform,
  ready,
  applyingManual,
  saving,
  error,
}

class TransformState {
  final TransformStatus status;
  final TransformParams params;
  final TransformParams? originalParams;
  final Uint8List? transformedImageBytes;
  final List<Uint8List>? referenceImages;
  final String? errorMessage;
  final String? cachedFullBase64;
  final String? cachedPreviewBase64;

  /// 서버가 계산한 "왜 이렇게 보정했는지" 한 문장.
  final String? paramsComment;

  /// 수평 보정·크롭 등 기하 편집. 저장 시 그대로 되돌려 보내야
  /// 저장본이 미리보기와 같아진다.
  final Map<String, dynamic>? autoEdits;

  /// 하늘/얼굴/배경 영역별 보정. 같은 이유로 보관한다.
  final Map<String, dynamic>? regionParams;

  /// 대표 사진에서 뽑은 톤 커브 제어점. 프리셋 이름으로 표현되지 않아
  /// 저장 시에도 그대로 되돌려 보내야 한다.
  final List<dynamic>? toneCurvePoints;

  /// 이 상태를 만든 분석에 넘긴 원본 파일 경로.
  final String? sourceImagePath;

  /// 분석 저장소가 앱 문서 폴더에 복사해 둔 경로 (히스토리 기록의 imagePath).
  /// 변형 화면은 이 둘 중 하나로 열리므로 둘 다 들고 있어야 같은 사진인지 안다.
  final String? savedImagePath;

  /// 이 결과가 저장된 분석 기록(DB 행) id. 다시 분석할 때 새 행을 만들지 않고
  /// 이 행을 갱신하는 데 쓴다.
  final int? recordId;

  /// 로딩이 AI 분석이 아니라 저장된 값으로 다시 그리는 중인지 (문구용).
  final bool restoring;

  /// AI 분석 진행 상황(서버 작업 단계·경과). 대기 화면 문구용 — 아직
  /// 서버가 알려 주지 않았으면 null.
  final AnalysisJobProgress? analysisProgress;

  const TransformState({
    this.status = TransformStatus.idle,
    this.params = const TransformParams(),
    this.originalParams,
    this.transformedImageBytes,
    this.referenceImages,
    this.errorMessage,
    this.cachedFullBase64,
    this.cachedPreviewBase64,
    this.paramsComment,
    this.autoEdits,
    this.regionParams,
    this.toneCurvePoints,
    this.sourceImagePath,
    this.savedImagePath,
    this.recordId,
    this.restoring = false,
    this.analysisProgress,
  });

  /// 이 상태(변형 결과)가 [imagePath] 사진의 것인지.
  ///
  /// provider가 전역이라, 다른 사진의 결과가 남아 있는 채로 변형 화면이
  /// 열리면 지금 사진의 Before 옆에 이전 사진의 After가 뜬다.
  ///
  /// 화면과 상태 모두 기록 id를 알면 id로 판별한다 (같은 기록이면 경로 표기가
  /// 달라도 같은 사진, 다른 기록이면 다른 사진). 어느 쪽이든 모르면 경로로 본다.
  bool belongsTo(String imagePath, {int? recordId}) {
    if (recordId != null && this.recordId != null) {
      return recordId == this.recordId;
    }
    return imagePath == sourceImagePath || imagePath == savedImagePath;
  }

  TransformState copyWith({
    TransformStatus? status,
    TransformParams? params,
    TransformParams? originalParams,
    Uint8List? transformedImageBytes,
    List<Uint8List>? referenceImages,
    String? errorMessage,
    String? cachedFullBase64,
    String? cachedPreviewBase64,
    String? paramsComment,
    Map<String, dynamic>? autoEdits,
    Map<String, dynamic>? regionParams,
    List<dynamic>? toneCurvePoints,
    String? sourceImagePath,
    String? savedImagePath,
    int? recordId,
    bool? restoring,
    AnalysisJobProgress? analysisProgress,
  }) {
    return TransformState(
      status: status ?? this.status,
      params: params ?? this.params,
      originalParams: originalParams ?? this.originalParams,
      transformedImageBytes: transformedImageBytes ?? this.transformedImageBytes,
      referenceImages: referenceImages ?? this.referenceImages,
      errorMessage: errorMessage,
      cachedFullBase64: cachedFullBase64 ?? this.cachedFullBase64,
      cachedPreviewBase64: cachedPreviewBase64 ?? this.cachedPreviewBase64,
      paramsComment: paramsComment ?? this.paramsComment,
      autoEdits: autoEdits ?? this.autoEdits,
      regionParams: regionParams ?? this.regionParams,
      toneCurvePoints: toneCurvePoints ?? this.toneCurvePoints,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      savedImagePath: savedImagePath ?? this.savedImagePath,
      recordId: recordId ?? this.recordId,
      restoring: restoring ?? this.restoring,
      analysisProgress: analysisProgress ?? this.analysisProgress,
    );
  }
}

class TransformNotifier extends Notifier<TransformState> {
  CancelToken? _manualCancelToken;
  CancelToken? _autoTransformCancelToken;

  /// [TransformState.transformedImageBytes]가 서버의 최종 화질 렌더링인지.
  /// 미리보기(저해상도) 바이트면 저장 폴백으로 쓰면 안 된다.
  bool _bytesAreFullQuality = false;

  @override
  TransformState build() => const TransformState();

  /// 진행 중인 자동 변형 요청을 취소한다.
  ///
  /// 상태도 idle로 되돌린다. provider가 전역(non-autoDispose)이라
  /// loadingAutoTransform이 남으면 다음 화면이 "분석 중"으로 오인한다.
  void cancelAutoTransform() {
    _autoTransformCancelToken?.cancel('사용자 취소');
    _autoTransformCancelToken = null;
    if (state.status == TransformStatus.loadingAutoTransform) {
      state = TransformState(referenceImages: state.referenceImages);
    }
  }

  /// [token]의 요청이 아직 유효한지 — 취소됐거나 새 요청에 밀렸으면 false.
  bool _isCurrent(CancelToken token) =>
      !token.isCancelled && identical(token, _autoTransformCancelToken);

  void updateParamsOnly(TransformParams params) {
    state = state.copyWith(params: params);
  }

  Future<void> loadReferenceImages() async {
    try {
      String userId = '';
      try {
        final authState = ref.read(instagramAuthProvider);
        userId = authState.userId ?? '';
      } catch (_) {}

      if (userId.isEmpty) return;

      if (state.referenceImages != null && state.referenceImages!.isNotEmpty) {
        return;
      }

      final repo = ref.read(analysisRepositoryDIProvider);
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

  /// AI 분석 + 변형을 돌린다 (~30-70초, 유료 호출).
  ///
  /// [recordId]가 있으면 그 기록을 갱신하고, 없으면 새 기록을 만든다.
  Future<({String analysisJson, String imagePath, int recordId})?>
      analyzeAndTransform(File imageFile, {int? recordId}) async {
    // 이전 요청이 있으면 취소
    _autoTransformCancelToken?.cancel('새 자동 변형 요청');
    // 필드가 아니라 지역 변수로 잡는다. 이미지 처리 도중 취소되면 필드는
    // null이 되어, 그대로 넘기면 취소된 요청이 서버로 나가 버린다.
    final token = CancelToken();
    _autoTransformCancelToken = token;
    _bytesAreFullQuality = false;

    // 새 사진을 시작할 때 이전 사진의 결과를 전부 비운다. copyWith는 null로
    // 되돌릴 수 없어 regionParams·톤 커브·보정 설명 등이 다음 사진에 새어 들었다.
    // 대표 사진은 사용자 단위라 유지한다.
    state = TransformState(
      status: TransformStatus.loadingAutoTransform,
      referenceImages: state.referenceImages,
      sourceImagePath: imageFile.path,
      recordId: recordId,
    );

    try {
      final repo = ref.read(analysisRepositoryDIProvider);
      final imageService = ref.read(imageServiceProvider);
      final styleProfile = ref.read(userStyleProfileProvider);

      String userId = '';
      try {
        final authState = ref.read(instagramAuthProvider);
        userId = authState.userId ?? '';
      } catch (_) {}

      final fullProcessed = await imageService.processImage(imageFile);
      final previewBase64 = await imageService.processPreviewImage(imageFile);
      if (!_isCurrent(token)) return null;

      state = state.copyWith(
        cachedFullBase64: fullProcessed.base64,
        cachedPreviewBase64: previewBase64,
      );

      final reshapeEnabled = await _reshapeEnabled();
      final skinRetouchEnabled = await _skinRetouchEnabled();
      if (!_isCurrent(token)) return null;

      final result = await repo.analyzeAndTransformRecord(
        imageFile: imageFile,
        styleProfile: styleProfile,
        userId: userId,
        reshapeEnabled: reshapeEnabled,
        skinRetouchEnabled: skinRetouchEnabled,
        cancelToken: token,
        recordId: recordId,
        onProgress: (progress) {
          // 새 요청에 밀렸거나 이미 끝난 요청의 진행 알림은 버린다
          if (!_isCurrent(token) ||
              state.status != TransformStatus.loadingAutoTransform) {
            return;
          }
          state = state.copyWith(analysisProgress: progress);
        },
      );
      if (!_isCurrent(token)) return null;

      final imageB64 = result.fullResult['image_base64'] as String?;
      final paramsMap = result.fullResult['params'] as Map<String, dynamic>?;
      final comment = result.fullResult['params_comment'] as String?;
      final analysisMap =
          result.fullResult['analysis'] as Map<String, dynamic>?;

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
        originalParams: aiParams,
        transformedImageBytes: base64Decode(imageB64),
        paramsComment: comment,
        autoEdits: analysisMap?['autoEdits'] as Map<String, dynamic>?,
        regionParams: analysisMap?['regionParams'] as Map<String, dynamic>?,
        toneCurvePoints: paramsMap?['tone_curve_points'] as List<dynamic>?,
        savedImagePath: result.imagePath,
        recordId: result.recordId,
      );
      _bytesAreFullQuality = true;

      return (
        analysisJson: result.analysisJson,
        imagePath: result.imagePath,
        recordId: result.recordId,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        developer.log('analyzeAndTransform cancelled (정상 취소)', name: 'Transform');
        return null;
      }
      developer.log('analyzeAndTransform failed: $e', name: 'Transform');
      // 새 요청에 밀린 이전 요청의 실패가 새 요청의 로딩 상태를 덮지 않게
      if (!_isCurrent(token)) return null;
      final msg = e.response?.statusCode != null
          ? ApiException(message: e.message ?? '', statusCode: e.response?.statusCode).userMessage
          : '인터넷 연결을 확인해 주세요';
      state = state.copyWith(
        status: TransformStatus.error,
        errorMessage: msg,
      );
    } catch (e) {
      developer.log('analyzeAndTransform failed: $e', name: 'Transform');
      if (!_isCurrent(token)) return null;
      final msg = e is ApiException ? e.userMessage : '분석 중 오류가 발생했습니다. 다시 시도해 주세요';
      state = state.copyWith(
        status: TransformStatus.error,
        errorMessage: msg,
      );
    }
    return null;
  }

  /// 기록에서 변형 화면을 연다.
  ///
  /// 기록에 변형 재현 정보(transformJson)가 있으면 AI를 부르지 않고
  /// apply-transform 한 번으로 같은 결과를 다시 그린다 — 새 기록도 만들지
  /// 않는다. 없으면(v3 이전 기록) 분석을 다시 돌리되 그 기록을 갱신한다.
  Future<({String analysisJson, String imagePath, int recordId})?> openRecord(
    int recordId,
    File imageFile,
  ) async {
    _autoTransformCancelToken?.cancel('기록 열기');
    final token = CancelToken();
    _autoTransformCancelToken = token;
    _bytesAreFullQuality = false;

    state = TransformState(
      status: TransformStatus.loadingAutoTransform,
      referenceImages: state.referenceImages,
      sourceImagePath: imageFile.path,
      recordId: recordId,
      restoring: true,
    );

    SavedAnalysis? saved;
    try {
      saved = await ref.read(analysisRepositoryDIProvider).loadRecord(recordId);
    } catch (e) {
      developer.log('loadRecord failed: $e', name: 'Transform');
    }
    if (!_isCurrent(token)) return null;

    final transform = saved?.transform;
    if (saved == null || transform == null) {
      // 재현 정보가 없는 옛 기록 — 한 번 분석해 그 기록에 채운다.
      // 기록이 지워졌으면(saved == null) 새 기록으로 남긴다.
      return analyzeAndTransform(imageFile, recordId: saved?.id);
    }

    final ok = await _restore(
      imageFile,
      transform,
      recordId: saved.id,
      savedImagePath: saved.imagePath,
      token: token,
    );
    if (!ok) return null;
    return (
      analysisJson: saved.analysisJson,
      imagePath: saved.imagePath,
      recordId: saved.id,
    );
  }

  /// 저장된 변형 값으로 상태를 채우고 최종 화질로 다시 그린다 (AI 호출 없음).
  Future<bool> _restore(
    File imageFile,
    StoredTransform transform, {
    required int recordId,
    required String savedImagePath,
    required CancelToken token,
  }) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final fullProcessed = await imageService.processImage(imageFile);
      final previewBase64 = await imageService.processPreviewImage(imageFile);
      if (!_isCurrent(token)) return false;

      var params = transform.transformParams;
      // 설정에서 얼굴/체형 보정을 끈 것이 확인되면 저장된 체형 값을 쓰지 않는다.
      // (분석 당시 켜져 있었을 수 있다. 서버도 꺼져 있으면 0으로 계산한다.)
      if (!await _reshapeEnabled()) {
        params = params.copyWith(
          faceSlim: 0.0,
          jawSharpen: 0.0,
          eyeEnlarge: 0.0,
          legStretch: 0.0,
          shoulderWidth: 0.0,
          waistSlim: 0.0,
        );
      }
      // 피부 보정을 꺼 두었으면 저장된 잡티 제거·피부 스무딩 값도 쓰지 않는다.
      var regionParams = transform.regionParams;
      if (!await _skinRetouchEnabled()) {
        final stripped = withoutSkinRetouch(params, regionParams);
        params = stripped.params;
        regionParams = stripped.regionParams;
      }
      if (!_isCurrent(token)) return false;

      state = state.copyWith(
        cachedFullBase64: fullProcessed.base64,
        cachedPreviewBase64: previewBase64,
        params: params,
        originalParams: params,
        paramsComment: transform.paramsComment,
        autoEdits: transform.autoEdits,
        regionParams: regionParams,
        toneCurvePoints: transform.toneCurvePoints,
        savedImagePath: savedImagePath,
        recordId: recordId,
      );

      // 저장·공유와 같은 요청 — 화면의 After가 저장본과 같아진다.
      final result = await _renderFullQuality(imageFile, cancelToken: token);
      if (!_isCurrent(token)) return false;

      final imageB64 = result['image_base64'] as String?;
      if (imageB64 == null) {
        state = state.copyWith(
          status: TransformStatus.error,
          errorMessage: '변형된 이미지를 받지 못했습니다',
        );
        return false;
      }
      state = state.copyWith(
        status: TransformStatus.ready,
        transformedImageBytes: base64Decode(imageB64),
      );
      _bytesAreFullQuality = true;
      return true;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return false;
      developer.log('restore failed: $e', name: 'Transform');
      if (!_isCurrent(token)) return false;
      state = state.copyWith(
        status: TransformStatus.error,
        errorMessage: '인터넷 연결을 확인해 주세요',
      );
    } catch (e) {
      developer.log('restore failed: $e', name: 'Transform');
      if (!_isCurrent(token)) return false;
      state = state.copyWith(
        status: TransformStatus.error,
        errorMessage: e is ApiException
            ? e.userMessage
            : '변형 결과를 불러오지 못했어요. 다시 시도해 주세요',
      );
    }
    return false;
  }

  Future<void> applyManual(File imageFile, TransformParams params) async {
    _manualCancelToken?.cancel('새 슬라이더 요청으로 인한 이전 요청 취소');
    _manualCancelToken = CancelToken();

    state = state.copyWith(
      status: TransformStatus.applyingManual,
      params: params,
      errorMessage: null,
    );

    try {
      final transformRepo = ref.read(transformRepositoryProvider);
      final cancelToken = _manualCancelToken;
      final skin = await _applySkinSetting(params, state.regionParams);
      if (cancelToken?.isCancelled ?? false) return;

      // reshape이 활성화되면 고해상도로 전송 (랜드마크 검출 정확도)
      final needsReshape = params.faceSlim >= 0.01 ||
          params.jawSharpen >= 0.01 ||
          params.eyeEnlarge >= 0.01 ||
          params.legStretch >= 0.01 ||
          params.shoulderWidth.abs() >= 0.01 ||
          params.waistSlim >= 0.01;

      final String? base64;
      final bool usePreview;
      if (needsReshape) {
        base64 = state.cachedFullBase64;
        usePreview = false;
      } else {
        base64 = state.cachedPreviewBase64;
        usePreview = base64 != null;
      }

      // 기하·영역 보정과 톤 커브도 함께 보낸다. 빼면 슬라이더를 건드리는 순간
      // 미리보기가 원본에 슬라이더만 얹은 그림으로 되돌아간다 — 수평 보정과
      // 크롭이 풀리고 영역별 보정이 사라져, 저장본과 다른 것을 보게 된다.
      // (e44dee2가 저장 경로에서 고친 것과 같은 문제가 미리보기에 남아 있었다.
      //  비싼 잡티 제거·피부 스무딩은 서버가 preview 플래그로 걸러낸다.)
      final result = await transformRepo.applyManualTransform(
        imageFile: base64 == null ? imageFile : null,
        imageBase64: base64,
        preview: usePreview,
        params: skin.params,
        autoEdits: state.autoEdits,
        regionParams: skin.regionParams,
        toneCurvePoints: state.toneCurvePoints,
        cancelToken: cancelToken,
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
      _bytesAreFullQuality = !usePreview;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        developer.log('applyManual cancelled (정상 취소)', name: 'Transform');
        return;
      }
      developer.log('applyManual failed: $e', name: 'Transform');
      final msg = e is ApiException
          ? (e as ApiException).userMessage
          : '변형 적용에 실패했습니다. 다시 시도해 주세요';
      state = state.copyWith(
        status: TransformStatus.ready,
        errorMessage: msg,
      );
    } catch (e) {
      developer.log('applyManual failed: $e', name: 'Transform');
      final msg = e is ApiException ? e.userMessage : '변형 적용에 실패했습니다. 다시 시도해 주세요';
      state = state.copyWith(
        status: TransformStatus.ready,
        errorMessage: msg,
      );
    }
  }

  /// 최종 화질로 변형 결과를 만든다 (저장·공유가 공유하는 경로).
  ///
  /// 원본에 현재 슬라이더 값 + 기하·영역 보정을 다시 태운다. 미리보기 바이트는
  /// 사용자가 슬라이더를 만졌을 때 최신이 아닐 수 있어 그대로 쓰지 않는다.
  ///
  /// 재렌더링이 실패하면, 화면의 After가 서버의 최종 화질 결과일 때만 그걸
  /// 대신 쓴다. 미리보기 해상도 바이트를 조용히 저장하지 않도록 그 외에는
  /// null을 돌려 호출부가 실패를 알리게 한다.
  Future<Uint8List?> renderForExport(File imageFile) async {
    try {
      final result = await _renderFullQuality(imageFile);
      final imageB64 = result['image_base64'] as String?;
      if (imageB64 != null) return base64Decode(imageB64);
      return _bytesAreFullQuality ? state.transformedImageBytes : null;
    } catch (e) {
      developer.log('renderForExport failed: $e', name: 'Transform');
      return _bytesAreFullQuality ? state.transformedImageBytes : null;
    }
  }

  /// 현재 상태 그대로 원본에 최종 화질 변형을 태우는 요청.
  /// 저장·공유([renderForExport])와 기록 복원([openRecord])이 함께 쓴다 —
  /// 둘이 다른 요청을 만들면 복원한 After와 저장본이 달라진다.
  ///
  /// 설정에서 피부 보정을 끄면 잡티 제거·피부 스무딩을 0으로 보낸다 —
  /// apply-transform은 받은 값을 그대로 쓰므로 앱이 직접 걸러야 한다.
  Future<Map<String, dynamic>> _renderFullQuality(
    File imageFile, {
    CancelToken? cancelToken,
  }) async {
    final transformRepo = ref.read(transformRepositoryProvider);
    final fullBase64 = state.cachedFullBase64;
    final skin = await _applySkinSetting(state.params, state.regionParams);
    return transformRepo.applyManualTransform(
      imageFile: fullBase64 == null ? imageFile : null,
      imageBase64: fullBase64,
      preview: false,
      params: skin.params,
      autoEdits: state.autoEdits,
      regionParams: skin.regionParams,
      toneCurvePoints: state.toneCurvePoints,
      cancelToken: cancelToken,
    );
  }

  /// 설정의 '피부 보정' 값. 읽지 못하면 기본값(켜짐).
  /// '얼굴/체형 보정' 설정. 로드 전이면 기다려서 읽는다 (읽기 실패 시 꺼짐).
  Future<bool> _reshapeEnabled() async {
    try {
      return await ref.read(reshapeEnabledSettingProvider.future);
    } catch (e) {
      developer.log('reshape setting read failed: $e', name: 'Transform');
      return false;
    }
  }

  Future<bool> _skinRetouchEnabled() async {
    try {
      return await ref.read(skinRetouchEnabledSettingProvider.future);
    } catch (e) {
      developer.log('skin retouch setting read failed: $e', name: 'Transform');
      return true;
    }
  }

  /// 피부 보정이 꺼져 있으면 apply-transform에 보낼 피부 값을 0으로 만든다.
  Future<({TransformParams params, Map<String, dynamic>? regionParams})>
      _applySkinSetting(
    TransformParams params,
    Map<String, dynamic>? regionParams,
  ) async {
    if (await _skinRetouchEnabled()) {
      return (params: params, regionParams: regionParams);
    }
    return withoutSkinRetouch(params, regionParams);
  }

  Future<String?> saveTransformedImage(File imageFile) async {
    state = state.copyWith(status: TransformStatus.saving);

    try {
      final bytes = await renderForExport(imageFile);

      if (bytes == null) {
        state = state.copyWith(
          status: TransformStatus.ready,
          errorMessage: state.transformedImageBytes == null
              ? '저장할 이미지가 없습니다'
              : '저장용 이미지를 만들지 못했어요. 다시 시도해 주세요',
        );
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = p.join(
        tempDir.path,
        'transformed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(savePath).writeAsBytes(bytes);
      await Gal.putImage(savePath, album: 'Gamdo');
      // 갤러리 저장은 끝났다. 임시 파일 정리 실패를 저장 실패로 알리지 않는다.
      try {
        await File(savePath).delete();
      } catch (_) {}

      await _saveFeedback();

      state = state.copyWith(
        status: TransformStatus.ready,
        transformedImageBytes: bytes,
      );
      _bytesAreFullQuality = true;
      developer.log('Saved transformed image to gallery (full resolution)', name: 'Transform');
      return savePath;
    } catch (e) {
      developer.log('saveTransformedImage failed: $e', name: 'Transform');
      final msg = e is ApiException ? e.userMessage : '저장에 실패했습니다. 다시 시도해 주세요';
      state = state.copyWith(
        status: TransformStatus.ready,
        errorMessage: msg,
      );
      return null;
    }
  }

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

      final hasChange = delta.values.any((v) => v.abs() > 0.001);
      if (!hasChange) return;

      final styleRepo = ref.read(styleRepositoryProvider);

      // 1. delta 저장
      await styleRepo.saveFeedback(userId: userId, delta: delta);

      // 2. 누적 피드백 로드 및 평균 계산
      final history = await styleRepo.loadFeedbackHistory(userId);
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
      await styleRepo.updateTargetParams(
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
