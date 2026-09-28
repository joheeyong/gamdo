import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/instagram_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/instagram_auth.dart';
import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] 구현체 — InstagramService + StorageService.
class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final StorageService _storage;
  final SessionService _session;

  AuthRepositoryImpl({
    required Dio dio,
    required StorageService storage,
    SessionService? session,
  })  : _dio = dio,
        _storage = storage,
        _session = session ?? SessionService(storage: storage);

  @override
  Future<InstagramAuth> restoreSession() async {
    final token = await _storage.getInstagramToken();
    final userId = await _storage.getInstagramUserId();
    final username = await _storage.getInstagramUsername();

    if (token != null && token.isNotEmpty) {
      return InstagramAuth(
        isConnected: true,
        accessToken: token,
        userId: userId,
        username: username,
      );
    }
    return const InstagramAuth();
  }

  @override
  Future<SessionValidation> validateSession() async {
    final token = await _storage.getInstagramToken();
    if (token == null || token.isEmpty) return SessionValidation.loggedOut;

    // 세션이 없거나 7일 이내 만료면 재발급. 구버전 서버(404)·오프라인은 조용히 통과.
    final result = await _session.refreshIfNeeded();
    if (result == SessionRefreshResult.instagramTokenInvalid) {
      return SessionValidation.loggedOut;
    }

    final userId = await _storage.getInstagramUserId();
    final signedIn = await _session.signInFirebase(userId);
    return signedIn
        ? SessionValidation.firebaseSignedIn
        : SessionValidation.connected;
  }

  @override
  Future<InstagramAuth> login() async {
    final prefs = await SharedPreferences.getInstance();
    final proxyUrl =
        ApiConstants.resolveProxyUrl(prefs.getString('proxy_url'));

    final service = InstagramService(
      dio: _dio,
      serverBaseUrl: proxyUrl,
    );

    // 1. OAuth 웹뷰로 authorization code 획득
    final code = await service.authenticate();

    // 2. 서버에서 access_token 교환
    final tokenData = await service.exchangeToken(code);
    final accessToken = tokenData['access_token'] as String;
    final userId = tokenData['user_id']?.toString() ?? '';

    // 3. 프로필 조회 (username)
    String? username;
    try {
      final profile = await service.fetchProfile(accessToken);
      username = profile['username'] as String?;
    } catch (e) {
      developer.log('Profile fetch failed: $e', name: 'AuthRepository');
    }

    // 4. 로컬에 저장
    await _storage.setInstagramToken(accessToken);
    await _storage.setInstagramUserId(userId);
    if (username != null) {
      await _storage.setInstagramUsername(username);
    }

    // 5. gamdo-agent 세션 저장 (세션 미설정/구버전 서버면 필드가 없다)
    //    → 없으면 /api/session으로 한 번 시도. 이어서 Firebase Auth 로그인.
    //    모두 실패해도 로그인 자체는 성공으로 둔다.
    await _storage.clearSession();
    if (!await _session.saveSessionFrom(tokenData)) {
      await _session.refreshSession();
    }
    await _session.signInFirebase(userId);

    return InstagramAuth(
      isConnected: true,
      accessToken: accessToken,
      userId: userId,
      username: username,
    );
  }

  @override
  Future<void> logout() async {
    await _storage.clearInstagram();
    await SessionService.signOutFirebase();
  }
}
