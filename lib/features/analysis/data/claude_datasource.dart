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
  }) async {
    final baseUrl = await _getBaseUrl();

    try {
      final response = await _dio.post(
        '$baseUrl/api/analyze-user',
        data: {
          'posts': posts,
          'feeds': feeds,
          'stories': stories,
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
