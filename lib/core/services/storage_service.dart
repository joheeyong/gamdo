import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_service.g.dart';

@riverpod
StorageService storageService(Ref ref) => StorageService();

class StorageService {
  StorageService({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  /// 민감한 토큰(Instagram access token, 세션 토큰)은 Keychain/Keystore에 둔다.
  final FlutterSecureStorage _secure;

  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _darkModeKey = 'dark_mode';
  static const String _proxyUrlKey = 'proxy_url';
  static const String _appTokenKey = 'app_token';
  static const String _instagramTokenKey = 'instagram_token';
  static const String _instagramUserIdKey = 'instagram_user_id';
  static const String _instagramUsernameKey = 'instagram_username';
  static const String _reshapeEnabledKey = 'reshape_enabled';
  static const String _skinRetouchEnabledKey = 'skin_retouch_enabled';
  static const String _editStyleKey = 'edit_style';
  static const String _editStylePromptedKey = 'edit_style_prompted';

  // secure storage 키
  static const String _secureInstagramTokenKey = 'instagram_token';
  static const String _sessionTokenKey = 'gamdo_session_token';
  static const String _sessionExpiresAtKey = 'gamdo_session_expires_at';

  /// secure storage에 토큰을 써 뒀는지 표시하는 prefs 플래그.
  /// - iOS Keychain은 앱을 지워도 남는다. 재설치(prefs 초기화) 뒤 옛 토큰으로
  ///   자동 로그인되지 않도록, 플래그가 있을 때만 secure storage를 읽는다.
  /// - 토큰이 없는 사용자는 Keychain에 접근하지 않는다.
  static const String _secureTokensMarkerKey = 'secure_tokens_present';

  Future<bool> _hasSecureTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_secureTokensMarkerKey) ?? false;
  }

  Future<void> _markSecureTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_secureTokensMarkerKey, true);
  }

  /// 세션 만료가 이 기간 안으로 다가오면 미리 재발급한다.
  static const Duration sessionRefreshWindow = Duration(days: 7);

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<String?> getProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proxyUrlKey);
  }

  Future<void> setProxyUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proxyUrlKey, url);
  }

  Future<String?> getAppToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appTokenKey);
  }

  Future<void> setAppToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appTokenKey, token);
  }

  // ── 얼굴/체형 보정 ──

  Future<bool> isReshapeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reshapeEnabledKey) ?? false;
  }

  Future<void> setReshapeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reshapeEnabledKey, value);
  }

  // ── 피부 보정 (잡티 제거·피부 결 정리) ──

  /// 기본값은 켜짐 — 기존 사용자는 지금처럼 피부 보정을 받는다.
  Future<bool> isSkinRetouchEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skinRetouchEnabledKey) ?? true;
  }

  Future<void> setSkinRetouchEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skinRetouchEnabledKey, value);
  }

  // ── 보정 스타일 ──

  /// 'auto'(내 피드 기준) 또는 trendCategory id. 저장된 값이 없으면 null.
  Future<String?> getEditStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_editStyleKey);
  }

  Future<void> setEditStyle(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_editStyleKey, value);
  }

  /// '보정 스타일을 골라 주세요' 안내를 이미 띄웠는지 (한 번만 띄운다).
  Future<bool> isEditStylePrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_editStylePromptedKey) ?? false;
  }

  Future<void> setEditStylePrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_editStylePromptedKey, true);
  }

  // ── Instagram ──

  /// Instagram access token — 앱 전체에서 이 메서드로만 읽는다.
  ///
  /// 예전 버전은 SharedPreferences에 평문으로 저장했다. 처음 읽을 때
  /// secure storage로 옮기고 prefs에서 지운다. secure storage가 실패하면
  /// prefs 값을 그대로 쓴다 — 기존 사용자의 로그인이 풀리지 않게.
  Future<String?> getInstagramToken() async {
    if (await _hasSecureTokens()) {
      try {
        final secured = await _secure.read(key: _secureInstagramTokenKey);
        if (secured != null && secured.isNotEmpty) return secured;
      } catch (e) {
        developer.log('Secure read failed: $e', name: 'StorageService');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_instagramTokenKey);
    if (legacy == null || legacy.isEmpty) return null;

    // 1회 마이그레이션: secure에 써지면 prefs에서 지운다.
    try {
      await _secure.write(key: _secureInstagramTokenKey, value: legacy);
      await _markSecureTokens();
      await prefs.remove(_instagramTokenKey);
    } catch (e) {
      developer.log('Token migration failed (prefs 유지): $e',
          name: 'StorageService');
    }
    return legacy;
  }

  Future<void> setInstagramToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _secure.write(key: _secureInstagramTokenKey, value: token);
      await _markSecureTokens();
      await prefs.remove(_instagramTokenKey);
    } catch (e) {
      // Keychain 접근 실패 시에도 로그인은 유지되도록 prefs에 둔다.
      developer.log('Secure write failed, prefs fallback: $e',
          name: 'StorageService');
      await prefs.setString(_instagramTokenKey, token);
    }
  }

  Future<String?> getInstagramUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instagramUserIdKey);
  }

  Future<void> setInstagramUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_instagramUserIdKey, userId);
  }

  Future<String?> getInstagramUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instagramUsernameKey);
  }

  Future<void> setInstagramUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_instagramUsernameKey, username);
  }

  /// Instagram 연결 정보 + 세션을 모두 지운다 (로그아웃).
  Future<void> clearInstagram() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_instagramTokenKey);
    await prefs.remove(_instagramUserIdKey);
    await prefs.remove(_instagramUsernameKey);
    if (await _hasSecureTokens()) {
      try {
        await _secure.delete(key: _secureInstagramTokenKey);
      } catch (e) {
        developer.log('Secure delete failed: $e', name: 'StorageService');
      }
      await clearSession();
    }
    await prefs.remove(_secureTokensMarkerKey);
  }

  Future<bool> isInstagramConnected() async {
    final token = await getInstagramToken();
    return token != null && token.isNotEmpty;
  }

  // ── gamdo-agent 세션 ──

  Future<String?> getSessionToken() async {
    if (!await _hasSecureTokens()) return null;
    try {
      final token = await _secure.read(key: _sessionTokenKey);
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      developer.log('Session read failed: $e', name: 'StorageService');
      return null;
    }
  }

  /// 세션 만료 시각 (unix 초). 없으면 null.
  Future<int?> getSessionExpiresAt() async {
    if (!await _hasSecureTokens()) return null;
    try {
      final raw = await _secure.read(key: _sessionExpiresAtKey);
      return raw == null ? null : int.tryParse(raw);
    } catch (e) {
      developer.log('Session read failed: $e', name: 'StorageService');
      return null;
    }
  }

  Future<void> setSession({
    required String token,
    required int expiresAt,
  }) async {
    try {
      await _secure.write(key: _sessionTokenKey, value: token);
      await _secure.write(
          key: _sessionExpiresAtKey, value: expiresAt.toString());
      await _markSecureTokens();
    } catch (e) {
      // 세션은 없어도 과도기 서버에서는 동작한다 — 저장 실패는 로그만.
      developer.log('Session write failed: $e', name: 'StorageService');
    }
  }

  Future<void> clearSession() async {
    if (!await _hasSecureTokens()) return;
    try {
      await _secure.delete(key: _sessionTokenKey);
      await _secure.delete(key: _sessionExpiresAtKey);
    } catch (e) {
      developer.log('Session delete failed: $e', name: 'StorageService');
    }
  }

  /// 세션이 없거나 [sessionRefreshWindow] 안에 만료되면 true.
  Future<bool> sessionNeedsRefresh({DateTime? now}) async {
    final token = await getSessionToken();
    final expiresAt = await getSessionExpiresAt();
    return sessionExpiringSoon(token: token, expiresAt: expiresAt, now: now);
  }
}

/// 세션 재발급이 필요한지 — 토큰/만료 시각이 없거나 만료가
/// [StorageService.sessionRefreshWindow] 안으로 다가왔으면 true.
bool sessionExpiringSoon({
  required String? token,
  required int? expiresAt,
  DateTime? now,
}) {
  if (token == null || token.isEmpty || expiresAt == null) return true;
  final nowSec = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  return expiresAt - nowSec <= StorageService.sessionRefreshWindow.inSeconds;
}
