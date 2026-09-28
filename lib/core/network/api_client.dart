import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_constants.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';

part 'api_client.g.dart';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
    headers: {
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip',
    },
  ));

  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => developer.log('$obj', name: 'DIO'),
  ));

  return dio;
}

/// gamdo-agent 요청에 인증 헤더를 붙이고, 세션 만료(401 session_invalid)면
/// 한 번 재발급 후 원요청을 1회 재시도한다.
///
/// - 세션 토큰이 있으면 `Bearer <session>`, 없으면 기존 app_token(하위호환).
/// - 세션 토큰은 gamdo-agent 주소(설정된 proxy URL과 같은 origin)로만 보낸다.
/// - 재발급/재시도는 별도 plain Dio로 해서 인터셉터 재귀를 피한다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    StorageService? storage,
    SessionService? sessionService,
    Dio? retryDio,
  })  : _storage = storage ?? StorageService(),
        _sessionServiceOverride = sessionService,
        _retryDioOverride = retryDio;

  final StorageService _storage;
  final SessionService? _sessionServiceOverride;
  final Dio? _retryDioOverride;

  late final SessionService _sessionService =
      _sessionServiceOverride ?? SessionService(storage: _storage);
  late final Dio _retryDio = _retryDioOverride ?? Dio();

  static const _retriedKey = 'gamdo_session_retried';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final isAgent = await _isGamdoAgent(options.uri);
      final session = isAgent ? await _storage.getSessionToken() : null;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer $session';
      } else if (!_isMetaHost(options.uri)) {
        final token = await _storage.getAppToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      developer.log('Auth header failed: $e', name: 'AuthInterceptor');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final shouldRefresh = err.response?.statusCode == 401 &&
        errorCodeOf(err.response?.data) == 'session_invalid' &&
        options.extra[_retriedKey] != true &&
        !options.uri.path.endsWith(SessionService.sessionPath) &&
        await _isGamdoAgent(options.uri);
    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final result = await _sessionService.refreshSession();
    if (result != SessionRefreshResult.refreshed) {
      // instagramTokenInvalid면 SessionService가 이미 로그아웃 이벤트를 보냈다.
      handler.next(err);
      return;
    }

    try {
      final retry = await _retryDio.fetch<dynamic>(await _retryOptions(options));
      handler.resolve(retry);
    } on DioException catch (e) {
      handler.next(e);
    } catch (e) {
      handler.next(err);
    }
  }

  Future<RequestOptions> _retryOptions(RequestOptions options) async {
    final session = await _storage.getSessionToken();
    final data = options.data;
    return options.copyWith(
      // FormData는 한 번 전송되면 재사용할 수 없어 복제한다.
      data: data is FormData ? data.clone() : data,
      headers: {
        ...options.headers,
        if (session != null) 'Authorization': 'Bearer $session',
      },
      extra: {...options.extra, _retriedKey: true},
    );
  }

  Future<bool> _isGamdoAgent(Uri uri) async {
    final proxy = ApiConstants.resolveProxyUrl(await _storage.getProxyUrl());
    return isSameOrigin(uri, Uri.tryParse(proxy));
  }
}

/// 두 URI의 scheme/host/port가 같은지.
bool isSameOrigin(Uri a, Uri? b) {
  if (b == null || b.host.isEmpty) return false;
  return a.scheme == b.scheme && a.host == b.host && a.port == b.port;
}

/// Instagram/Meta 호스트에는 앱 토큰을 보내지 않는다.
bool _isMetaHost(Uri uri) {
  final host = uri.host;
  return host == 'instagram.com' ||
      host.endsWith('.instagram.com') ||
      host.endsWith('.cdninstagram.com') ||
      host == 'facebook.com' ||
      host.endsWith('.facebook.com') ||
      host.endsWith('.fbcdn.net');
}
