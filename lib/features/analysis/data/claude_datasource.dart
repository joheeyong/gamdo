import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_resume_signal.dart';
import '../domain/entities/analysis_job_progress.dart';

/// 서버가 분석 작업 API를 모른다 (구버전, 404/405) — 동기 엔드포인트로 폴백.
class JobsEndpointUnsupported implements Exception {
  const JobsEndpointUnsupported();
}

class GamdoAgentDatasource {
  final Dio _dio;

  /// 폴링 대기. 테스트에서 가짜로 바꿔 시간을 흘리지 않는다.
  final Future<void> Function(Duration) _delay;

  /// 마감 계산용 시계.
  final DateTime Function() _now;

  /// 앱 foreground 복귀 신호 — 받으면 기다리지 않고 바로 폴링한다.
  final Stream<void> _resumeSignal;

  /// 작업 API가 없다고 확인된 서버 주소. 매번 404를 한 번씩 더 치지 않게.
  final Set<String> _jobsUnsupported = {};

  /// 작업 상태 폴링 간격 (계약 5절).
  static const pollInterval = Duration(milliseconds: 1500);

  /// 오래 걸리는 작업은 간격을 늘린다.
  static const slowPollInterval = Duration(seconds: 3);
  static const slowPollAfter = Duration(seconds: 20);

  /// 폴링 요청 하나의 제한 시간.
  static const pollRequestTimeout = Duration(seconds: 20);

  /// 작업 시작부터 결과까지 전체 마감.
  static const jobDeadline = Duration(minutes: 10);

  GamdoAgentDatasource(
    this._dio, {
    Future<void> Function(Duration)? delay,
    DateTime Function()? now,
    Stream<void>? resumeSignal,
  })  : _delay = delay ?? _defaultDelay,
        _now = now ?? DateTime.now,
        _resumeSignal = resumeSignal ?? AppResumeSignal.instance.stream;

  static Future<void> _defaultDelay(Duration d) => Future<void>.delayed(d);

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('proxy_url');
    // 저장된 값이 비어있거나 없으면 기본값 사용
    if (saved == null || saved.isEmpty) return ApiConstants.defaultProxyUrl;
    return saved;
  }

  /// 사용자 게시글/피드/스토리를 분석하여 스타일 프로필을 반환
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts = const [],
    List<Map<String, dynamic>> feeds = const [],
    List<Map<String, dynamic>> stories = const [],
    String userId = '',
  }) async {
    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/api/analyze-user',
        data: {
          'posts': posts,
          'feeds': feeds,
          'stories': stories,
          'user_id': userId,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// 사용자 스타일에 맞춰 사진 보정 가이드를 반환
  Future<Map<String, dynamic>> transformPhoto({
    required Map<String, dynamic> styleProfile,
    required String imageBase64,
    String mediaType = 'image/jpeg',
  }) async {
    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/api/transform-photo',
        data: {
          'style_profile': styleProfile,
          'image_base64': imageBase64,
          'media_type': mediaType,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// 사진 분석 + 변형을 한 번에 수행.
  ///
  /// 서버 작업(job)으로 돌린다: 작업을 시작하고 짧은 요청으로 결과를 폴링한다.
  /// 긴 연결 하나에 묶지 않으므로 앱이 백그라운드에 다녀와 소켓이 끊겨도
  /// 서버는 계속 처리하고, 돌아오면 바로 결과를 받는다.
  /// 구버전 서버(작업 API 404/405)면 기존 동기 엔드포인트로 폴백한다.
  ///
  /// 반환값은 기존 동기 엔드포인트 응답과 같은 모양이다
  /// (success, analysis, image_base64, params, params_comment ...).
  /// [cancelToken]이 취소되면 폴링을 멈추고 DioException(cancel)을 던진다
  /// (서버 작업은 끝까지 돌고 30분 뒤 사라진다 — 같은 사진 재시도 시 재사용).
  /// [onProgress]는 단계(대기/분석/렌더링)와 경과 시간을 받는다.
  Future<Map<String, dynamic>> analyzeAndTransform({
    required String imageBase64,
    required Map<String, dynamic> styleProfile,
    String userId = '',
    String mediaType = 'image/jpeg',
    bool reshapeEnabled = false,
    CancelToken? cancelToken,
    void Function(AnalysisJobProgress progress)? onProgress,
  }) async {
    final baseUrl = await _getBaseUrl();
    final body = _analyzeBody(
      imageBase64: imageBase64,
      styleProfile: styleProfile,
      userId: userId,
      mediaType: mediaType,
      reshapeEnabled: reshapeEnabled,
    );

    if (_jobsUnsupported.contains(baseUrl)) {
      return _analyzeAndTransformSync(baseUrl, body, cancelToken, onProgress);
    }

    final deadline = _now().add(jobDeadline);
    Map<String, dynamic> job;
    try {
      job = await _startJob(baseUrl, body, cancelToken);
    } on JobsEndpointUnsupported {
      _jobsUnsupported.add(baseUrl);
      return _analyzeAndTransformSync(baseUrl, body, cancelToken, onProgress);
    }

    var jobId = job['job_id'] as String;
    var restarted = false;
    final startedAt = _now();
    _emitProgress(job, onProgress);
    // 합치기로 이미 끝난 작업을 받았으면 기다리지 않고 바로 조회한다.
    var pollNow = job['status'] == 'done' || job['status'] == 'error';

    while (true) {
      _throwIfCancelled(cancelToken);
      if (!pollNow) {
        final sinceStart = _now().difference(startedAt);
        await _waitForNextPoll(
          sinceStart < slowPollAfter ? pollInterval : slowPollInterval,
          cancelToken,
        );
        _throwIfCancelled(cancelToken);
      }
      pollNow = false;
      if (_now().isAfter(deadline)) {
        throw const ApiException(
          message: 'Analysis job did not finish in time',
          statusCode: 504,
        );
      }

      try {
        job = await getAnalyzeJob(jobId, cancelToken: cancelToken);
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          // 서버 재시작 등으로 작업이 사라졌다 — 한 번만 다시 시작한다.
          // 같은 요청이므로 서버 분석 캐시가 있으면 곧바로 끝난다.
          if (restarted) rethrow;
          restarted = true;
          try {
            job = await _startJob(baseUrl, body, cancelToken);
          } on JobsEndpointUnsupported {
            _jobsUnsupported.add(baseUrl);
            return _analyzeAndTransformSync(
                baseUrl, body, cancelToken, onProgress);
          }
          jobId = job['job_id'] as String;
          _emitProgress(job, onProgress);
          pollNow = job['status'] == 'done' || job['status'] == 'error';
          continue;
        }
        // 네트워크 오류·타임아웃(백그라운드에서 끊긴 소켓 포함)·5xx는
        // 일시 오류로 보고 마감까지 계속 조회한다.
        if (_isTransient(e)) continue;
        rethrow;
      }

      _emitProgress(job, onProgress);
      switch (job['status']) {
        case 'done':
          final result = job['result'];
          if (result is! Map) {
            throw const ApiException(
              message: 'Analysis job finished without result',
              statusCode: 200,
            );
          }
          if (result['success'] == false) {
            throw ApiException(
              message: result['error']?.toString() ?? 'Unknown error',
              statusCode: 200,
            );
          }
          return Map<String, dynamic>.from(result);
        case 'error':
          // 기존 동기 엔드포인트의 success:false와 같은 방식으로 알린다.
          throw ApiException(
            message: job['error']?.toString() ?? 'Unknown error',
            statusCode: 200,
          );
      }
    }
  }

  /// 분석 작업을 시작한다 (`POST /api/jobs/analyze-and-transform`).
  ///
  /// 같은 요청이 진행 중/보관 중이면 서버가 그 작업을 돌려준다(합치기).
  /// 서버가 작업 API를 모르면(404/405) [JobsEndpointUnsupported]를 던진다.
  Future<Map<String, dynamic>> startAnalyzeJob({
    required String imageBase64,
    required Map<String, dynamic> styleProfile,
    String userId = '',
    String mediaType = 'image/jpeg',
    bool reshapeEnabled = false,
    CancelToken? cancelToken,
  }) async {
    final baseUrl = await _getBaseUrl();
    return _startJob(
      baseUrl,
      _analyzeBody(
        imageBase64: imageBase64,
        styleProfile: styleProfile,
        userId: userId,
        mediaType: mediaType,
        reshapeEnabled: reshapeEnabled,
      ),
      cancelToken,
    );
  }

  /// 분석 작업 상태를 조회한다 (`GET /api/jobs/{id}`).
  ///
  /// 200이면 응답 맵(status/stage/elapsed_sec/result/error)을 그대로 돌려준다.
  /// HTTP 오류·네트워크 오류는 [ApiException.fromDio]로 (404 = 작업 없음).
  Future<Map<String, dynamic>> getAnalyzeJob(
    String jobId, {
    CancelToken? cancelToken,
  }) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await _dio.get(
        '$baseUrl/api/jobs/$jobId',
        options: Options(
          sendTimeout: pollRequestTimeout,
          receiveTimeout: pollRequestTimeout,
        ),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw ApiException(
        message: 'Unexpected job response',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic> _analyzeBody({
    required String imageBase64,
    required Map<String, dynamic> styleProfile,
    required String userId,
    required String mediaType,
    required bool reshapeEnabled,
  }) =>
      {
        'image_base64': imageBase64,
        'style_profile': styleProfile,
        'user_id': userId,
        'media_type': mediaType,
        // 설정의 '얼굴/체형 보정' 토글. 서버로 보내지 않으면 꺼 둔 사용자도
        // 체형이 변형된다 (기본값은 꺼짐).
        'reshape_enabled': reshapeEnabled,
      };

  Future<Map<String, dynamic>> _startJob(
    String baseUrl,
    Map<String, dynamic> body,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/jobs/analyze-and-transform',
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['job_id'] is String) {
        return Map<String, dynamic>.from(data);
      }
      throw ApiException(
        message: data is Map
            ? (data['error']?.toString() ?? 'Unknown error')
            : 'Unexpected job response',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) throw const JobsEndpointUnsupported();
      final data = e.response?.data;
      // 503 busy 등 서버가 사람용 메시지를 줬으면 그걸 쓴다.
      if (data is Map && data['error'] != null) {
        throw ApiException(
          message: data['error'].toString(),
          statusCode: code,
          data: data,
          dioType: e.type,
        );
      }
      throw ApiException.fromDio(e);
    }
  }

  /// 구버전 서버용 — 긴 요청 하나로 분석 + 변형을 받는다.
  Future<Map<String, dynamic>> _analyzeAndTransformSync(
    String baseUrl,
    Map<String, dynamic> body,
    CancelToken? cancelToken,
    void Function(AnalysisJobProgress progress)? onProgress,
  ) async {
    onProgress?.call(const AnalysisJobProgress(
      stage: AnalysisJobStage.analyzing,
      resumable: false,
    ));
    try {
      final response = await _dio.post(
        '$baseUrl/api/analyze-and-transform',
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
        cancelToken: cancelToken,
      );

      return _handleTransformResponse(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  void _emitProgress(
    Map<String, dynamic> job,
    void Function(AnalysisJobProgress progress)? onProgress,
  ) {
    if (onProgress == null) return;
    final stage =
        AnalysisJobStage.tryParse(job['stage'], status: job['status']);
    if (stage == null) return;
    final sec = job['elapsed_sec'];
    onProgress(AnalysisJobProgress(
      stage: stage,
      elapsed: sec is num
          ? Duration(milliseconds: (sec * 1000).round())
          : Duration.zero,
    ));
  }

  /// 다음 폴링까지 기다린다. 앱이 foreground로 돌아오거나 취소되면 바로 끝난다.
  Future<void> _waitForNextPoll(Duration interval, CancelToken? token) {
    final done = Completer<void>();
    void finish([Object? _]) {
      if (!done.isCompleted) done.complete();
    }

    final sub = _resumeSignal.listen(finish);
    _delay(interval).then(finish, onError: finish);
    token?.whenCancel.then(finish);
    return done.future.whenComplete(sub.cancel);
  }

  static void _throwIfCancelled(CancelToken? token) {
    if (token == null || !token.isCancelled) return;
    throw token.cancelError ??
        DioException.requestCancelled(
          requestOptions: RequestOptions(path: 'api/jobs'),
          reason: 'cancelled',
        );
  }

  static const _transientTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.unknown,
  };

  static bool _isTransient(ApiException e) {
    final code = e.statusCode;
    if (code == null) return e.dioType == null || _transientTypes.contains(e.dioType);
    return code >= 500 || code == 408 || code == 429;
  }

  /// AI 분석 기반 자동 변형 — 분석 결과+스타일 프로필로 이미지 자동 보정
  Future<Map<String, dynamic>> autoTransform({
    required String imageBase64,
    required Map<String, dynamic> analysis,
    Map<String, dynamic>? styleProfile,
  }) async {
    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/api/auto-transform',
        data: {
          'image_base64': imageBase64,
          'analysis': analysis,
          'style_profile': styleProfile,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      return _handleTransformResponse(response);
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// 슬라이더 값으로 수동 변형 — 원본에서 항상 새로 적용
  /// [cancelToken]이 전달되면 요청 취소에 활용 (슬라이더 디바운스 시 이전 요청 취소)
  Future<Map<String, dynamic>> applyTransform({
    required String imageBase64,
    bool preview = false,
    double brightness = 0.0,
    double contrast = 0.0,
    double clarity = 0.0,
    double dehaze = 0.0,
    double highlights = 0.0,
    double shadows = 0.0,
    double saturation = 0.0,
    double temperature = 0.0,
    double blemishRemoval = 0.0,
    double skinSmoothing = 0.0,
    double vignette = 0.0,
    double sharpness = 0.0,
    double grain = 0.0,
    String toneCurvePreset = 'linear',
    double toneCurveStrength = 0.0,
    double splitShadowHue = 0.0,
    double splitShadowStrength = 0.0,
    double splitHighlightHue = 0.0,
    double splitHighlightStrength = 0.0,
    Map<String, Map<String, double>>? hslAdjust,
    double faceSlim = 0.0,
    double jawSharpen = 0.0,
    double eyeEnlarge = 0.0,
    double legStretch = 0.0,
    double shoulderWidth = 0.0,
    double waistSlim = 0.0,
    double autoWb = 0.0,
    double denoise = 0.0,
    double backgroundBlur = 0.0,
    Map<String, dynamic>? autoEdits,
    Map<String, dynamic>? regionParams,
    List<dynamic>? toneCurvePoints,
    CancelToken? cancelToken,
  }) async {
    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/api/apply-transform',
        data: {
          'image_base64': imageBase64,
          'preview': preview,
          'auto_wb': autoWb,
          'denoise': denoise,
          'background_blur': backgroundBlur,
          // 기하·영역 보정을 함께 보내야 저장본이 미리보기와 같아진다
          'auto_edits': ?autoEdits,
          'region_params': ?regionParams,
          'tone_curve_points': ?toneCurvePoints,
          'brightness': brightness,
          'contrast': contrast,
          'clarity': clarity,
          'dehaze': dehaze,
          'highlights': highlights,
          'shadows': shadows,
          'saturation': saturation,
          'temperature': temperature,
          'blemish_removal': blemishRemoval,
          'skin_smoothing': skinSmoothing,
          'vignette': vignette,
          'sharpness': sharpness,
          'grain': grain,
          'tone_curve_preset': toneCurvePreset,
          'tone_curve_strength': toneCurveStrength,
          'split_shadow_hue': splitShadowHue,
          'split_shadow_strength': splitShadowStrength,
          'split_highlight_hue': splitHighlightHue,
          'split_highlight_strength': splitHighlightStrength,
          'hsl_adjust': ?hslAdjust,
          'face_slim': faceSlim,
          'jaw_sharpen': jawSharpen,
          'eye_enlarge': eyeEnlarge,
          'leg_stretch': legStretch,
          'shoulder_width': shoulderWidth,
          'waist_slim': waistSlim,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
        ),
        cancelToken: cancelToken,
      );

      return _handleTransformResponse(response);
    } on DioException catch (e) {
      // 요청 취소는 정상 흐름이므로 그대로 rethrow — 호출부에서 처리
      if (e.type == DioExceptionType.cancel) rethrow;
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// 사용자 대표 사진 base64 목록을 조회
  Future<List<String>> fetchReferenceImages(String userId) async {
    if (userId.isEmpty) return [];

    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.get(
        '$baseUrl/api/reference-images/$userId',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          final images = data['images'] as List<dynamic>? ?? [];
          return images.cast<String>();
        }
      }
      return [];
    } on DioException {
      return [];
    }
  }

  /// 변형 API 응답 처리 — success/image_base64/params 구조
  Map<String, dynamic> _handleTransformResponse(Response response) {
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return Map<String, dynamic>.from(data);
      } else if (data is Map && data['success'] == false) {
        throw ApiException(
          message: data['error'] ?? 'Unknown error',
          statusCode: response.statusCode,
        );
      }
      return data as Map<String, dynamic>;
    } else {
      throw ApiException(
        message: 'API request failed',
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      } else if (data is Map && data['success'] == false) {
        throw ApiException(
          message: data['error'] ?? 'Unknown error',
          statusCode: response.statusCode,
        );
      }
      return data as Map<String, dynamic>;
    } else {
      throw ApiException(
        message: 'API request failed',
        statusCode: response.statusCode,
      );
    }
  }
}
