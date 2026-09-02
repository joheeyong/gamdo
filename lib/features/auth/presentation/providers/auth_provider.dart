import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
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
  @override
  InstagramAuth build() => const InstagramAuth();

  /// SharedPreferences에서 저장된 토큰 복원 + Firebase에서 스타일 프로필 로드.
  Future<void> init() async {
    final authRepo = ref.read(authRepositoryProvider);
    final restored = await authRepo.restoreSession();

    if (restored.isConnected) {
      state = restored;

      // Firebase RTDB에서 스타일 프로필 로드
      final userId = restored.userId;
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
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.login();
      state = result;
      return true;
    } catch (e) {
      developer.log('Instagram login failed: $e', name: 'InstagramAuth');
      state = state.copyWith(isLoading: false, error: e.toString());
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

final instagramAuthProvider =
    NotifierProvider<InstagramAuthNotifier, InstagramAuth>(() {
  return InstagramAuthNotifier();
});
