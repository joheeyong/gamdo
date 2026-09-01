import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';

class GamdoAgentDatasource {
  final Dio _dio;

  GamdoAgentDatasource(this._dio);

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
          receiveTimeout: const Duration(minutes: 5),
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
          receiveTimeout: const Duration(minutes: 5),
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

  /// 사진 분석 + 변형을 한 번에 수행
  Future<Map<String, dynamic>> analyzeAndTransform({
    required String imageBase64,
    required Map<String, dynamic> styleProfile,
    String userId = '',
    String mediaType = 'image/jpeg',
  }) async {
    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/api/analyze-and-transform',
        data: {
          'image_base64': imageBase64,
          'style_profile': styleProfile,
          'user_id': userId,
          'media_type': mediaType,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
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
  Future<Map<String, dynamic>> applyTransform({
    required String imageBase64,
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
  }) async {
    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/api/apply-transform',
        data: {
          'image_base64': imageBase64,
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
          if (hslAdjust != null) 'hsl_adjust': hslAdjust,
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
      );

      return _handleTransformResponse(response);
    } on DioException catch (e) {
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
