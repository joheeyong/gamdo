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
import '../../../../core/providers/style_profile_provider.dart';
import '../../../../core/services/image_service.dart';
import '../../di/analysis_providers.dart';
import '../../domain/entities/transform_params.dart';

// Re-export TransformParams so existing consumers still see it here
export '../../domain/entities/transform_params.dart';

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
  });

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
    );
  }
}

class TransformNotifier extends Notifier<TransformState> {
  CancelToken? _manualCancelToken;
  CancelToken? _autoTransformCancelToken;

  @override
  TransformState build() => const TransformState();

  /// 진행 중인 자동 변형 요청을 취소한다.
  void cancelAutoTransform() {
    _autoTransformCancelToken?.cancel('사용자 취소');
    _autoTransformCancelToken = null;
  }

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

  Future<({String analysisJson, String imagePath})?> analyzeAndTransform(File imageFile) async {
    // 이전 요청이 있으면 취소
    _autoTransformCancelToken?.cancel('새 자동 변형 요청');
    _autoTransformCancelToken = CancelToken();

    state = state.copyWith(
      status: TransformStatus.loadingAutoTransform,
      errorMessage: null,
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

      state = state.copyWith(
        cachedFullBase64: fullProcessed.base64,
        cachedPreviewBase64: previewBase64,
      );

      final result = await repo.analyzeAndTransform(
        imageFile: imageFile,
        styleProfile: styleProfile,
        userId: userId,
        cancelToken: _autoTransformCancelToken,
      );

      final imageB64 = result.fullResult['image_base64'] as String?;
      final paramsMap = result.fullResult['params'] as Map<String, dynamic>?;
      final comment = result.fullResult['params_comment'] as String?;

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
      );

      return (analysisJson: result.analysisJson, imagePath: result.imagePath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        developer.log('analyzeAndTransform cancelled (정상 취소)', name: 'Transform');
        return null;
      }
      developer.log('analyzeAndTransform failed: $e', name: 'Transform');
      final msg = e.response?.statusCode != null
          ? ApiException(message: e.message ?? '', statusCode: e.response?.statusCode).userMessage
          : '인터넷 연결을 확인해 주세요';
      state = state.copyWith(
        status: TransformStatus.error,
        errorMessage: msg,
      );
    } catch (e) {
      developer.log('analyzeAndTransform failed: $e', name: 'Transform');
      final msg = e is ApiException ? e.userMessage : '분석 중 오류가 발생했습니다. 다시 시도해 주세요';
      state = state.copyWith(
        status: TransformStatus.error,
        errorMessage: msg,
      );
    }
    return null;
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

      final result = await transformRepo.applyManualTransform(
        imageFile: base64 == null ? imageFile : null,
        imageBase64: base64,
        preview: usePreview,
        params: params,
        cancelToken: _manualCancelToken,
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

  Future<String?> saveTransformedImage(File imageFile) async {
    state = state.copyWith(status: TransformStatus.saving);

    try {
      final transformRepo = ref.read(transformRepositoryProvider);
      final params = state.params;

      final fullBase64 = state.cachedFullBase64;
      final result = await transformRepo.applyManualTransform(
        imageFile: fullBase64 == null ? imageFile : null,
        imageBase64: fullBase64,
        preview: false,
        params: params,
      );

      final imageB64 = result['image_base64'] as String?;
      final bytes = imageB64 != null
          ? base64Decode(imageB64)
          : state.transformedImageBytes;

      if (bytes == null) {
        state = state.copyWith(
          status: TransformStatus.ready,
          errorMessage: '저장할 이미지가 없습니다',
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
      await File(savePath).delete();

      await _saveFeedback();

      state = state.copyWith(
        status: TransformStatus.ready,
        transformedImageBytes: bytes,
      );
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
