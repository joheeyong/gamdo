import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../features/auth/data/instagram_constants.dart';

/// Instagram OAuth + Media 조회 서비스.
///
/// 토큰 교환은 gamdo-agent 서버를 경유하여 client_secret을 보호한다.
class InstagramService {
  InstagramService({required this.dio, required this.serverBaseUrl});

  final Dio dio;
  final String serverBaseUrl;

  /// Instagram OAuth 로그인 → authorization code 획득.
  ///
  /// redirect_uri는 서버의 /api/instagram/callback 을 사용.
  /// Instagram → 서버(HTTPS) → gamdo://oauth/instagram?code=... → 앱.
  Future<String> authenticate() async {
    // 서버 콜백 URL을 redirect_uri로 사용
    final serverRedirectUri = '$serverBaseUrl/api/instagram/callback';

    final uri = Uri.parse(InstagramConstants.authorizeUrl).replace(
      queryParameters: {
        'client_id': InstagramConstants.clientId,
        'redirect_uri': serverRedirectUri,
        'response_type': 'code',
        'scope': InstagramConstants.scope,
      },
    );

    final result = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: InstagramConstants.callbackScheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('Instagram OAuth code not received');
    }

    // '#_' 접미사 제거 (Instagram이 붙이는 경우 있음)
    return code.replaceAll('#_', '');
  }

  /// authorization code → access_token 교환 (서버 경유).
  Future<Map<String, dynamic>> exchangeToken(String code) async {
    final serverRedirectUri = '$serverBaseUrl/api/instagram/callback';
    final response = await dio.post(
      '$serverBaseUrl/api/instagram/exchange-token',
      data: {
        'code': code,
        'redirect_uri': serverRedirectUri,
      },
    );
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Token exchange failed');
    }
    return body['data'] as Map<String, dynamic>;
  }

  /// 사용자 미디어 목록 조회 (서버 프록시).
  Future<List<Map<String, dynamic>>> fetchMedia(String accessToken) async {
    final response = await dio.post(
      '$serverBaseUrl/api/instagram/media',
      data: {'access_token': accessToken},
    );
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Media fetch failed');
    }
    final items = body['data'] as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  }

  /// 사용자 스토리 목록 조회 (서버 프록시).
  Future<List<Map<String, dynamic>>> fetchStories(String accessToken) async {
    final response = await dio.post(
      '$serverBaseUrl/api/instagram/stories',
      data: {'access_token': accessToken},
    );
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Stories fetch failed');
    }
    final items = body['data'] as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  }

  /// 사용자 프로필 조회.
  Future<Map<String, dynamic>> fetchProfile(String accessToken) async {
    final response = await dio.get(
      '${InstagramConstants.graphApiBaseUrl}/me',
      queryParameters: {
        'fields': 'user_id,username',
        'access_token': accessToken,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
