/// 설정 CRUD 인터페이스.
abstract class SettingsRepository {
  Future<String?> getProxyUrl();
  Future<void> setProxyUrl(String url);
  Future<String?> getAppToken();
  Future<void> setAppToken(String token);
  Future<bool> isReshapeEnabled();
  Future<void> setReshapeEnabled(bool value);
  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool value);
}
