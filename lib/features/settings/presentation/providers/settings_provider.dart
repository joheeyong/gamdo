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

/// 설정의 '얼굴/체형 보정' 토글 (기본 꺼짐).
///
/// keepAlive — autoDispose였을 때는 설정 화면이 떠 있지 않으면 분석 경로가
/// 로딩 상태를 읽어 `?? false`로 떨어졌다. 켜 둔 사용자도 항상 꺼짐으로 전송됐다.
@Riverpod(keepAlive: true)
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

/// 설정의 '피부 보정' 토글 (기본 켜짐).
///
/// keepAlive — 분석·저장 경로가 `.future`로 읽는다. autoDispose면 설정 화면이
/// 떠 있지 않을 때 매번 새로 읽혀 로딩 상태를 보게 되고, 기본값(켜짐)으로
/// 잘못 보낼 수 있다.
@Riverpod(keepAlive: true)
class SkinRetouchEnabledSetting extends _$SkinRetouchEnabledSetting {
  @override
  FutureOr<bool> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return await repo.isSkinRetouchEnabled();
  }

  Future<void> toggle() async {
    final current = state.value ?? true;
    final newValue = !current;
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setSkinRetouchEnabled(newValue);
    state = AsyncData(newValue);
  }
}
