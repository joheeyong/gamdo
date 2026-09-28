import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/api_constants.dart';
import '../network/auth_events.dart';
import 'storage_service.dart';

/// `/api/session` 재발급 결과.
enum SessionRefreshResult {
  /// 새 세션을 받아 저장했다.
  refreshed,

  /// Instagram 토큰이 무효/만료 — 로그아웃 처리했다.
  instagramTokenInvalid,

  /// 저장된 Instagram 토큰이 없다.
  noInstagramToken,

  /// 서버가 엔드포인트를 모르거나(404, 구버전), 세션 미설정, 네트워크 오류 등.
  /// 조용히 넘어간다.
  unavailable,
}

/// gamdo-agent 세션 토큰 발급/갱신 + Firebase Auth 로그인.
///
/// 인터셉터 재귀를 피하려고 앱의 dioProvider가 아닌 별도의 plain Dio를 쓴다.
/// 상태가 없는 클래스라 어디서든 `SessionService()`로 만들어 써도 된다 —
/// 동시 재발급 잠금은 static으로 공유한다.
class SessionService {
  SessionService({Dio? dio, StorageService? storage})
      : _dio = dio ?? _defaultDio(),
        _storage = storage ?? StorageService();

  final Dio _dio;
  final StorageService _storage;

  static const sessionPath = '/api/session';
  static const firebaseTokenPath = '/api/firebase-token';

  /// 진행 중인 재발급. 병렬 요청이 401을 동시에 받아도 한 번만 호출한다.
  static Future<SessionRefreshResult>? _inflight;

  static Dio _defaultDio() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        // 서버가 graph.instagram.com을 호출하므로 약간 여유를 둔다.
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ));

  Future<String> _baseUrl() async {
    final url = ApiConstants.resolveProxyUrl(await _storage.getProxyUrl());
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// exchange-token/session 응답의 `data`에서 세션 필드를 꺼내 저장한다.
  /// 필드가 없으면(세션 미설정 서버) false.
  Future<bool> saveSessionFrom(Map<String, dynamic> data) async {
    final token = data['session_token'];
    final expiresAt = _parseInt(data['session_expires_at']);
    if (token is! String || token.isEmpty || expiresAt == null) return false;
    await _storage.setSession(token: token, expiresAt: expiresAt);
    return true;
  }

  /// 세션이 없거나 7일 이내 만료면 재발급한다.
  Future<SessionRefreshResult?> refreshIfNeeded() async {
    if (!await _storage.sessionNeedsRefresh()) return null;
    return refreshSession();
  }

  /// `POST /api/session`으로 세션을 (재)발급한다. 동시 호출은 하나로 합친다.
  Future<SessionRefreshResult> refreshSession() {
    final running = _inflight;
    if (running != null) return running;
    final future = _refresh().whenComplete(() => _inflight = null);
    _inflight = future;
    return future;
  }

  Future<SessionRefreshResult> _refresh() async {
    final igToken = await _storage.getInstagramToken();
    if (igToken == null || igToken.isEmpty) {
      return SessionRefreshResult.noInstagramToken;
    }

    // 로그인 때 저장한 user_id를 함께 보낸다. exchange-token의 user_id와 /me의
    // user_id가 다른 ID 체계일 수 있어, 서버는 이 값이 토큰 소유자의 것이면
    // 그대로 발급한다 — 세션 uid·RTDB 경로(users/{userId})가 로그인 때와 같아진다.
    final storedUserId = await _storage.getInstagramUserId();

    try {
      final response = await _dio.post(
        '${await _baseUrl()}$sessionPath',
        data: {
          'access_token': igToken,
          if (storedUserId != null && storedUserId.isNotEmpty)
            'user_id': storedUserId,
        },
      );
      final body = response.data;
      if (body is! Map || body['success'] != true || body['data'] is! Map) {
        developer.log('Session refresh: unexpected body', name: 'Session');
        return SessionRefreshResult.unavailable;
      }
      final data = Map<String, dynamic>.from(body['data'] as Map);
      if (!await saveSessionFrom(data)) return SessionRefreshResult.unavailable;
      await _checkUserId(data['user_id']?.toString());
      developer.log('Session refreshed', name: 'Session');
      return SessionRefreshResult.refreshed;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          errorCodeOf(e.response?.data) == 'instagram_token_invalid') {
        developer.log('Instagram token invalid — logging out', name: 'Session');
        await _handleInstagramTokenInvalid();
        return SessionRefreshResult.instagramTokenInvalid;
      }
      // 404(구버전 서버)·네트워크 오류 등은 조용히 넘어간다.
      developer.log(
          'Session refresh unavailable: ${e.response?.statusCode ?? e.type}',
          name: 'Session');
      return SessionRefreshResult.unavailable;
    } catch (e) {
      developer.log('Session refresh failed: $e', name: 'Session');
      return SessionRefreshResult.unavailable;
    }
  }

  /// 저장된 user_id와 서버가 확인한 user_id가 다르면 경고만 남긴다.
  /// (RTDB 경로 users/{userId}와 Firebase uid가 일치해야 규칙을 통과한다.)
  Future<void> _checkUserId(String? serverUserId) async {
    if (serverUserId == null || serverUserId.isEmpty) return;
    final stored = await _storage.getInstagramUserId();
    if (stored == null || stored.isEmpty) {
      await _storage.setInstagramUserId(serverUserId);
    } else if (stored != serverUserId) {
      developer.log(
          'user_id mismatch: stored=$stored, session=$serverUserId',
          name: 'Session');
    }
  }

  Future<void> _handleInstagramTokenInvalid() async {
    await _storage.clearInstagram();
    await signOutFirebase();
    AuthEvents.emit(AuthEventType.instagramTokenInvalid);
  }

  /// 세션으로 Firebase custom token을 받아 FirebaseAuth에 로그인한다.
  ///
  /// 서버에 서비스 계정이 없거나(503) 구버전(404)이거나 무엇이든 실패하면
  /// 조용히 false — 앱은 Firebase Auth 없이도 동작한다.
  Future<bool> signInFirebase(String? userId) async {
    try {
      final auth = FirebaseAuth.instance;
      final current = auth.currentUser;
      if (current != null && userId != null && current.uid == userId) {
        return true;
      }

      final session = await _storage.getSessionToken();
      if (session == null) return false;

      final response = await _dio.post(
        '${await _baseUrl()}$firebaseTokenPath',
        data: const <String, dynamic>{},
        options: Options(headers: {'Authorization': 'Bearer $session'}),
      );
      final body = response.data;
      final token = (body is Map && body['success'] == true && body['data'] is Map)
          ? (body['data'] as Map)['firebase_token']
          : null;
      if (token is! String || token.isEmpty) return false;

      if (current != null) await auth.signOut();
      final credential = await auth.signInWithCustomToken(token);
      final uid = credential.user?.uid;
      if (userId != null && uid != userId) {
        developer.log('Firebase uid($uid) != userId($userId)',
            name: 'Session');
      }
      developer.log('Firebase signed in', name: 'Session');
      return true;
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      developer.log('Firebase sign-in skipped: ${status ?? e}',
          name: 'Session');
      return false;
    }
  }

  static Future<void> signOutFirebase() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      developer.log('Firebase sign-out failed: $e', name: 'Session');
    }
  }
}

/// 서버 에러 응답(`{"success": false, "error_code": ...}`)에서 코드를 꺼낸다.
String? errorCodeOf(Object? data) {
  if (data is Map) {
    final code = data['error_code'];
    if (code is String) return code;
    // FastAPI HTTPException 기본 형식 대비: {"detail": {"error_code": ...}}
    final detail = data['detail'];
    if (detail is Map && detail['error_code'] is String) {
      return detail['error_code'] as String;
    }
  }
  return null;
}

int? _parseInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
