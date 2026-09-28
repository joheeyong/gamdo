import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_events.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/style_profile_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/instagram_auth.dart';
import '../../domain/repositories/auth_repository.dart';

// Re-export InstagramAuth so consumers that import auth_provider see it
export '../../domain/entities/instagram_auth.dart';

/// DI: AuthRepository interface → implementation 바인딩.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dio: ref.read(dioProvider),
    storage: ref.read(storageServiceProvider),
  );
});

class InstagramAuthNotifier extends Notifier<InstagramAuth> {
  /// Instagram 토큰 만료(60일) 등으로 재연결이 필요할 때 보여줄 문구.
  static const reconnectMessage = 'Instagram 연결이 만료되었습니다. 다시 연결해 주세요';

  @override
  InstagramAuth build() {
    // 네트워크 계층(세션 재발급)이 Instagram 토큰 무효를 알리면 연결 해제 상태로.
    final sub = AuthEvents.stream.listen((event) {
      if (event == AuthEventType.instagramTokenInvalid) {
        developer.log('Instagram token invalid → disconnected',
            name: 'InstagramAuth');
        state = const InstagramAuth(error: reconnectMessage);
      }
    });
    ref.onDispose(sub.cancel);
    return const InstagramAuth();
  }

  /// 저장된 토큰 복원 + Firebase에서 스타일 프로필 로드.
  ///
  /// 서버 세션 확인/Firebase 로그인은 스플래시를 붙잡지 않도록 뒤에서 한다.
  Future<void> init() async {
    final authRepo = ref.read(authRepositoryProvider);
    final restored = await authRepo.restoreSession();

    if (restored.isConnected) {
      state = restored;
      await _loadStyleProfile(restored.userId);
      unawaited(_validateSession(restored.userId));
    }
  }

  Future<void> _validateSession(String? userId) async {
    try {
      final result = await ref.read(authRepositoryProvider).validateSession();
      if (!ref.mounted) return;
      switch (result) {
        case SessionValidation.loggedOut:
          if (state.isConnected) {
            state = const InstagramAuth(error: reconnectMessage);
          }
        case SessionValidation.firebaseSignedIn:
          // 규칙 배포 후 첫 실행이면 인증 전 프로필 읽기가 거부됐을 수 있다.
          if (ref.read(userStyleProfileProvider) == null) {
            await _loadStyleProfile(userId);
          }
        case SessionValidation.connected:
          break;
      }
    } catch (e) {
      developer.log('Session validation failed: $e', name: 'InstagramAuth');
    }
  }

  /// Firebase RTDB에서 스타일 프로필 로드
  Future<void> _loadStyleProfile(String? userId) async {
    if (userId == null || userId.isEmpty) return;
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

  /// Instagram OAuth 로그인 → 토큰 교환 → 저장.
  Future<bool> login() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.login();
      state = result;
      return true;
    } catch (e) {
      developer.log('Instagram login failed: $e', name: 'InstagramAuth');
      // 사용자가 로그인 창을 닫은 건 오류가 아니다 — 메시지 없이 원래대로.
      state = state.copyWith(
        isLoading: false,
        error: isLoginCancelled(e) ? null : loginErrorMessage(e),
      );
      return false;
    }
  }

  /// Instagram 연결 해제.
  Future<void> logout() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
    ref.read(userStyleProfileProvider.notifier).state = null;
    state = const InstagramAuth();
  }
}

/// flutter_web_auth_2는 사용자가 인증 창을 닫으면
/// `PlatformException(code: 'CANCELED')`를 던진다.
bool isLoginCancelled(Object e) =>
    e is PlatformException && e.code == 'CANCELED';

/// 로그인 실패를 사용자에게 보여줄 문장으로 바꾼다 (원문 예외는 로그로만).
String loginErrorMessage(Object e) {
  if (e is ApiException) return e.userMessage;
  if (e is DioException) return ApiException.fromDio(e).userMessage;
  return 'Instagram 로그인에 실패했습니다. 다시 시도해 주세요';
}

final instagramAuthProvider =
    NotifierProvider<InstagramAuthNotifier, InstagramAuth>(() {
  return InstagramAuthNotifier();
});
