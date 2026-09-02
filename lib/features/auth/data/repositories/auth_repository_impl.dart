import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/instagram_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/instagram_auth.dart';
import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] 구현체 — InstagramService + StorageService.
class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  AuthRepositoryImpl({
    required Dio dio,
    required StorageService storage,
  })  : _dio = dio,
        _storage = storage;

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
  Future<InstagramAuth> login() async {
    final prefs = await SharedPreferences.getInstance();
    final proxyUrl =
        prefs.getString('proxy_url') ?? ApiConstants.defaultProxyUrl;

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
  }
}
