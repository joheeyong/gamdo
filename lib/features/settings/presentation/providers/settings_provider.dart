import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/storage_service.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

part 'settings_provider.g.dart';

/// DI: SettingsRepository interface → implementation 바인딩.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(storage: ref.read(storageServiceProvider));
});

@riverpod
class ProxyUrlSetting extends _$ProxyUrlSetting {
  @override
  FutureOr<String> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return await repo.getProxyUrl() ?? '';
  }

  Future<void> save(String url) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setProxyUrl(url);
    state = AsyncData(url);
  }
}

@riverpod
class AppTokenSetting extends _$AppTokenSetting {
  @override
  FutureOr<String> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return await repo.getAppToken() ?? '';
  }

  Future<void> save(String token) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setAppToken(token);
    state = AsyncData(token);
  }
}

@riverpod
class ReshapeEnabledSetting extends _$ReshapeEnabledSetting {
  @override
  FutureOr<bool> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return await repo.isReshapeEnabled();
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    final newValue = !current;
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setReshapeEnabled(newValue);
    state = AsyncData(newValue);
  }
}
