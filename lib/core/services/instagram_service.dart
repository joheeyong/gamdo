import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../features/auth/data/instagram_constants.dart';

/// Instagram OAuth + Media 조회 서비스.
///
/// 토큰 교환은 gamdo-agent 서버를 경유하여 client_secret을 보호한다.
class InstagramService {
  InstagramService({required this.dio, required this.serverBaseUrl});

  final Dio dio;
  final String serverBaseUrl;

  /// OAuth redirect_uri. 인증 요청과 토큰 교환에 똑같은 값을 써야 한다.
  String get redirectUri => InstagramConstants.redirectUriOverride.isNotEmpty
      ? InstagramConstants.redirectUriOverride
      : '$serverBaseUrl/api/instagram/callback';

  /// CSRF 방지용 state. 인증 요청마다 새로 만들고, 돌아온 값과 같아야 받는다.
  @visibleForTesting
  static String newState([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Instagram OAuth 로그인 → authorization code 획득.
  ///
  /// Instagram → redirect_uri(서버 콜백 또는 호스팅 콜백 페이지)
  /// → gamdo://oauth/instagram?code=...&state=... → 앱.
  /// state가 보낸 값과 다르면(다른 사람의 인증 코드를 끼워 넣는 로그인 위조) 거부한다.
  Future<String> authenticate() async {
    final state = newState();
    final uri = Uri.parse(InstagramConstants.authorizeUrl).replace(
      queryParameters: {
        'client_id': InstagramConstants.clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': InstagramConstants.scope,
        'state': state,
      },
    );

    final result = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: InstagramConstants.callbackScheme,
    );
    return codeFromCallback(result, state);
  }

  /// 콜백 URL에서 인증 코드를 꺼낸다. state가 다르거나 코드가 없으면 예외.
  @visibleForTesting
  static String codeFromCallback(String callbackUrl, String expectedState) {
    final params = Uri.parse(callbackUrl).queryParameters;
    final returned = (params['state'] ?? '').replaceAll('#_', '');
    if (returned != expectedState) {
      throw Exception('Instagram OAuth state mismatch');
    }
    final code = params['code'];
    if (code == null || code.isEmpty) {
      throw Exception('Instagram OAuth code not received');
    }
    // '#_' 접미사 제거 (Instagram이 붙이는 경우 있음)
    return code.replaceAll('#_', '');
  }

  /// authorization code → access_token 교환 (서버 경유).
  Future<Map<String, dynamic>> exchangeToken(String code) async {
    final response = await dio.post(
      '$serverBaseUrl/api/instagram/exchange-token',
      data: {
        'code': code,
        'redirect_uri': redirectUri,
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
