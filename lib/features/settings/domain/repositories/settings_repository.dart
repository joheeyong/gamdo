/// 설정 CRUD 인터페이스.
abstract class SettingsRepository {
  Future<String?> getProxyUrl();
  Future<void> setProxyUrl(String url);
  Future<String?> getAppToken();
  Future<void> setAppToken(String token);
  Future<bool> isReshapeEnabled();
  Future<void> setReshapeEnabled(bool value);
  Future<bool> isSkinRetouchEnabled();
  Future<void> setSkinRetouchEnabled(bool value);
  Future<String?> getEditStyle();
  Future<void> setEditStyle(String value);
  Future<bool> isEditStylePrompted();
  Future<void> setEditStylePrompted();
  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool value);
}
