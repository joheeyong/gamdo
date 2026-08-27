import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/analysis_prompt.dart';
import '../../../core/network/api_exception.dart';

class ClaudeRemoteDatasource {
  final Dio _dio;

  ClaudeRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> analyzeImage(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    final proxyUrl =
        prefs.getString('proxy_url') ?? ApiConstants.defaultProxyUrl;

    try {
      final response = await _dio.post(
        '$proxyUrl${ApiConstants.analysisEndpoint}',
        data: {
          'model': ApiConstants.claudeModel,
          'max_tokens': 4096,
          'system': AnalysisPrompt.systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': AnalysisPrompt.analysisPrompt,
                },
              ],
            },
          ],
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Handle proxy response format - extract the text content
        String jsonStr;
        if (data is Map && data.containsKey('content')) {
          // Standard Claude API response format
          final content = data['content'] as List;
          jsonStr = content
              .where((c) => c['type'] == 'text')
              .map((c) => c['text'])
              .join();
        } else if (data is Map && data.containsKey('result')) {
          // Proxy may wrap the result
          jsonStr = data['result'] is String
              ? data['result']
              : jsonEncode(data['result']);
        } else if (data is String) {
          jsonStr = data;
        } else {
          jsonStr = jsonEncode(data);
        }

        // Clean JSON string (remove markdown code blocks if present)
        jsonStr = jsonStr.trim();
        if (jsonStr.startsWith('```json')) {
          jsonStr = jsonStr.substring(7);
        } else if (jsonStr.startsWith('```')) {
          jsonStr = jsonStr.substring(3);
        }
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
        jsonStr = jsonStr.trim();

        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: 'API request failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
