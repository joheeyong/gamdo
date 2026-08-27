import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/analysis/presentation/analysis_provider.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../services/firebase_service.dart';
import '../services/instagram_service.dart';
import '../services/storage_service.dart';

/// Instagram 연결 상태.
class InstagramAuth {
  const InstagramAuth({
    this.isConnected = false,
    this.accessToken,
    this.userId,
    this.username,
    this.isLoading = false,
    this.error,
  });

  final bool isConnected;
  final String? accessToken;
  final String? userId;
  final String? username;
  final bool isLoading;
  final String? error;

  InstagramAuth copyWith({
    bool? isConnected,
    String? accessToken,
    String? userId,
    String? username,
    bool? isLoading,
    String? error,
  }) {
    return InstagramAuth(
      isConnected: isConnected ?? this.isConnected,
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InstagramAuthNotifier extends Notifier<InstagramAuth> {
  @override
  InstagramAuth build() => const InstagramAuth();

  /// SharedPreferences에서 저장된 토큰 복원 + Firebase에서 스타일 프로필 로드.
  Future<void> init() async {
    final storage = StorageService();
    final token = await storage.getInstagramToken();
    final userId = await storage.getInstagramUserId();
    final username = await storage.getInstagramUsername();

    if (token != null && token.isNotEmpty) {
      state = InstagramAuth(
        isConnected: true,
        accessToken: token,
        userId: userId,
        username: username,
      );

      // Firebase RTDB에서 스타일 프로필 로드
      if (userId != null && userId.isNotEmpty) {
        try {
          final firebaseService = ref.read(firebaseServiceProvider);
          final data = await firebaseService.getStyleProfile(userId);
          if (data != null && data['styleProfile'] != null) {
            final profile =
                Map<String, dynamic>.from(data['styleProfile'] as Map);
            ref.read(userStyleProfileProvider.notifier).state = profile;
            developer.log('Style profile loaded from Firebase',
                name: 'InstagramAuth');
          }
        } catch (e) {
          developer.log('Failed to load style profile: $e',
              name: 'InstagramAuth');
        }
      }
    }
  }

  /// Instagram OAuth 로그인 → 토큰 교환 → 저장.
  Future<bool> login() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final proxyUrl =
          prefs.getString('proxy_url') ?? ApiConstants.defaultProxyUrl;
      final dio = ref.read(dioProvider);

      final service = InstagramService(
        dio: dio,
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
        developer.log('Profile fetch failed: $e', name: 'InstagramAuth');
      }

      // 4. 로컬에 저장
      final storage = StorageService();
      await storage.setInstagramToken(accessToken);
      await storage.setInstagramUserId(userId);
      if (username != null) {
        await storage.setInstagramUsername(username);
      }

      state = InstagramAuth(
        isConnected: true,
        accessToken: accessToken,
        userId: userId,
        username: username,
      );

      return true;
    } catch (e) {
      developer.log('Instagram login failed: $e', name: 'InstagramAuth');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Instagram 연결 해제.
  Future<void> logout() async {
    final storage = StorageService();
    await storage.clearInstagram();
    ref.read(userStyleProfileProvider.notifier).state = null;
    state = const InstagramAuth();
  }
}

final instagramAuthProvider =
    NotifierProvider<InstagramAuthNotifier, InstagramAuth>(() {
  return InstagramAuthNotifier();
});
