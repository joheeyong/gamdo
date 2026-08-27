import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_service.g.dart';

@riverpod
StorageService storageService(Ref ref) => StorageService();

class StorageService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _darkModeKey = 'dark_mode';
  static const String _proxyUrlKey = 'proxy_url';
  static const String _appTokenKey = 'app_token';

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
}
