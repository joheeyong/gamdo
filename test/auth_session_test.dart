import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/constants/api_constants.dart';
import 'package:gamdo/core/network/api_client.dart';
import 'package:gamdo/core/network/auth_events.dart';
import 'package:gamdo/core/services/session_service.dart';
import 'package:gamdo/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 경로별로 미리 정한 응답을 돌려주는 가짜 어댑터. 받은 요청을 기록한다.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final FutureOr<(int, Object?)> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_FakeAdapter adapter) => Dio()..httpClientAdapter = adapter;

const _agent = ApiConstants.defaultProxyUrl;

void main() {
  late StorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    storage = StorageService();
  });

  group('StorageService Instagram 토큰', () {
    test('예전 prefs 토큰을 secure storage로 옮기고 prefs에서 지운다', () async {
      SharedPreferences.setMockInitialValues({'instagram_token': 'old-ig'});

      expect(await storage.getInstagramToken(), 'old-ig');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('instagram_token'), isNull);
      // 옮긴 뒤에도 계속 읽힌다.
      expect(await storage.getInstagramToken(), 'old-ig');
      expect(await storage.isInstagramConnected(), isTrue);
    });

    test('재설치(prefs 비어 있음) 뒤 Keychain에 남은 옛 토큰은 쓰지 않는다', () async {
      FlutterSecureStorage.setMockInitialValues({
        'instagram_token': 'stale',
        'gamdo_session_token': 'stale-session',
      });
      final fresh = StorageService();
      expect(await fresh.getInstagramToken(), isNull);
      expect(await fresh.getSessionToken(), isNull);
    });

    test('clearInstagram은 토큰·세션을 모두 지운다', () async {
      await storage.setInstagramToken('ig');
      await storage.setInstagramUserId('u1');
      await storage.setSession(token: 's', expiresAt: 123);

      await storage.clearInstagram();

      expect(await storage.getInstagramToken(), isNull);
      expect(await storage.getInstagramUserId(), isNull);
      expect(await storage.getSessionToken(), isNull);
      expect(await storage.getSessionExpiresAt(), isNull);
    });
  });

  group('sessionExpiringSoon', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1000000 * 1000);
    int inDays(int d) => 1000000 + d * 86400;

    test('세션이 없으면 재발급', () {
      expect(sessionExpiringSoon(token: null, expiresAt: null, now: now),
          isTrue);
    });
    test('7일 이내 만료면 재발급', () {
      expect(sessionExpiringSoon(token: 't', expiresAt: inDays(6), now: now),
          isTrue);
    });
    test('넉넉히 남았으면 그대로', () {
      expect(sessionExpiringSoon(token: 't', expiresAt: inDays(20), now: now),
          isFalse);
    });
  });

  group('SessionService', () {
    test('exchange-token 응답의 세션 필드를 저장한다 (없으면 false)', () async {
      final service = SessionService(storage: storage, dio: Dio());
      expect(await service.saveSessionFrom({'access_token': 'x'}), isFalse);
      expect(
        await service.saveSessionFrom(
            {'session_token': 'v1.a.b', 'session_expires_at': 999}),
        isTrue,
      );
      expect(await storage.getSessionToken(), 'v1.a.b');
      expect(await storage.getSessionExpiresAt(), 999);
    });

    test('구버전 서버(404)면 조용히 unavailable, 로그인 유지', () async {
      await storage.setInstagramToken('ig');
      final adapter = _FakeAdapter((_) => (404, {'detail': 'Not Found'}));
      final service = SessionService(storage: storage, dio: _dioWith(adapter));

      expect(await service.refreshSession(), SessionRefreshResult.unavailable);
      expect(await storage.getInstagramToken(), 'ig');
    });

    for (final (status, code) in [
      (502, 'instagram_unavailable'),
      (503, 'session_not_configured'),
    ]) {
      test('$status $code면 로그아웃하지 않고 조용히 넘어간다', () async {
        await storage.setInstagramToken('ig');
        final adapter = _FakeAdapter(
            (_) => (status, {'success': false, 'error_code': code}));
        final service =
            SessionService(storage: storage, dio: _dioWith(adapter));
        expect(
            await service.refreshSession(), SessionRefreshResult.unavailable);
        expect(await storage.getInstagramToken(), 'ig');
      });
    }

    test('instagram_token_invalid면 저장소를 비우고 로그아웃 이벤트', () async {
      await storage.setInstagramToken('ig');
      final adapter = _FakeAdapter((_) => (
            401,
            {'success': false, 'error_code': 'instagram_token_invalid'},
          ));
      final service = SessionService(storage: storage, dio: _dioWith(adapter));
      final events = <AuthEventType>[];
      final sub = AuthEvents.stream.listen(events.add);
      addTearDown(sub.cancel);

      expect(await service.refreshSession(),
          SessionRefreshResult.instagramTokenInvalid);
      await Future<void>.delayed(Duration.zero);
      expect(await storage.getInstagramToken(), isNull);
      expect(events, [AuthEventType.instagramTokenInvalid]);
    });

    test('저장된 user_id를 함께 보내 로그인 때와 같은 uid로 발급받는다', () async {
      await storage.setInstagramToken('ig');
      await storage.setInstagramUserId('777');
      Object? sent;
      final adapter = _FakeAdapter((o) {
        sent = o.data;
        return (
          200,
          {
            'success': true,
            'data': {
              'session_token': 's',
              'session_expires_at': 2000000000,
              'user_id': '777',
            },
          },
        );
      });
      final service = SessionService(storage: storage, dio: _dioWith(adapter));

      expect(await service.refreshSession(), SessionRefreshResult.refreshed);
      expect(sent, {'access_token': 'ig', 'user_id': '777'});
    });

    test('동시 재발급 요청은 한 번만 서버를 호출한다', () async {
      await storage.setInstagramToken('ig');
      final adapter = _FakeAdapter((o) async {
        expect(o.data, {'access_token': 'ig'});
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return (
          200,
          {
            'success': true,
            'data': {
              'session_token': 'new-session',
              'session_expires_at': 2000000000,
              'user_id': 'u1',
            },
          },
        );
      });
      final service = SessionService(storage: storage, dio: _dioWith(adapter));

      final results = await Future.wait(
          [service.refreshSession(), service.refreshSession()]);

      expect(results, everyElement(SessionRefreshResult.refreshed));
      expect(adapter.requests, hasLength(1));
      expect(await storage.getSessionToken(), 'new-session');
      expect(await storage.getInstagramUserId(), 'u1');
    });

    test('Firebase 토큰은 세션이 없으면 요청하지 않는다', () async {
      final adapter = _FakeAdapter((_) => (500, null));
      final service = SessionService(storage: storage, dio: _dioWith(adapter));
      expect(await service.signInFirebase('u1'), isFalse);
      expect(adapter.requests, isEmpty);
    });
  });

  group('AuthInterceptor', () {
    test('세션이 있으면 gamdo-agent에만 세션 Bearer를 보낸다', () async {
      await storage.setAppToken('app');
      await storage.setSession(token: 'sess', expiresAt: 2000000000);
      final adapter = _FakeAdapter((_) => (200, {'success': true}));
      final dio = _dioWith(adapter)
        ..interceptors.add(AuthInterceptor(storage: storage));

      await dio.get('$_agent/api/x');
      await dio.get('https://graph.instagram.com/me');

      expect(adapter.requests[0].headers['Authorization'], 'Bearer sess');
      expect(adapter.requests[1].headers['Authorization'], isNull);
    });

    test('세션이 없으면 기존 app_token을 보낸다', () async {
      await storage.setAppToken('app');
      final adapter = _FakeAdapter((_) => (200, {'success': true}));
      final dio = _dioWith(adapter)
        ..interceptors.add(AuthInterceptor(storage: storage));

      await dio.get('$_agent/api/x');
      expect(adapter.requests.single.headers['Authorization'], 'Bearer app');
    });

    test('401 session_invalid → 재발급 후 원요청을 1회 재시도', () async {
      await storage.setInstagramToken('ig');
      await storage.setSession(token: 'old', expiresAt: 2000000000);
      final adapter = _FakeAdapter((o) {
        if (o.uri.path == SessionService.sessionPath) {
          return (
            200,
            {
              'success': true,
              'data': {
                'session_token': 'fresh',
                'session_expires_at': 2000000000,
              },
            },
          );
        }
        if (o.headers['Authorization'] == 'Bearer fresh') {
          return (200, {'success': true, 'data': 'ok'});
        }
        return (401, {'success': false, 'error_code': 'session_invalid'});
      });
      final dio = _dioWith(adapter)
        ..interceptors.add(AuthInterceptor(
          storage: storage,
          sessionService:
              SessionService(storage: storage, dio: _dioWith(adapter)),
          retryDio: _dioWith(adapter),
        ));

      final res = await dio.post('$_agent/api/analyze-user', data: {'a': 1});

      expect(res.data['data'], 'ok');
      expect(adapter.requests.map((r) => r.uri.path), [
        '/api/analyze-user',
        SessionService.sessionPath,
        '/api/analyze-user',
      ]);
    });

    test('재발급이 불가하면(구버전 서버) 원래 401을 그대로 돌려준다', () async {
      await storage.setInstagramToken('ig');
      final adapter = _FakeAdapter((o) => o.uri.path ==
              SessionService.sessionPath
          ? (404, {'detail': 'Not Found'})
          : (401, {'success': false, 'error_code': 'session_invalid'}));
      final dio = _dioWith(adapter)
        ..interceptors.add(AuthInterceptor(
          storage: storage,
          sessionService:
              SessionService(storage: storage, dio: _dioWith(adapter)),
          retryDio: _dioWith(adapter),
        ));

      await expectLater(
        dio.get('$_agent/api/x'),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 401)),
      );
      expect(adapter.requests, hasLength(2));
      expect(await storage.getInstagramToken(), 'ig');
    });
  });
}
