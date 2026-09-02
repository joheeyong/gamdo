import '../../../../core/services/storage_service.dart';
import '../../domain/repositories/settings_repository.dart';

/// [SettingsRepository] 구현체 — StorageService에 위임.
class SettingsRepositoryImpl implements SettingsRepository {
  final StorageService _storage;

  SettingsRepositoryImpl({required StorageService storage})
      : _storage = storage;

  @override
  Future<String?> getProxyUrl() => _storage.getProxyUrl();

  @override
  Future<void> setProxyUrl(String url) => _storage.setProxyUrl(url);

  @override
  Future<String?> getAppToken() => _storage.getAppToken();

  @override
  Future<void> setAppToken(String token) => _storage.setAppToken(token);

  @override
  Future<bool> isReshapeEnabled() => _storage.isReshapeEnabled();

  @override
  Future<void> setReshapeEnabled(bool value) => _storage.setReshapeEnabled(value);

  @override
  Future<bool> isDarkMode() => _storage.isDarkMode();

  @override
  Future<void> setDarkMode(bool value) => _storage.setDarkMode(value);
}
