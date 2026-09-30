import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/style_profile_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/edit_style.dart';
import '../../domain/repositories/settings_repository.dart';

export '../../domain/entities/edit_style.dart';

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

/// 설정의 '보정 스타일' — 'auto'(내 피드 기준) 또는 trendCategory id.
///
/// keepAlive — 분석 경로가 `.future`로 읽는다 (피부 보정 설정과 같은 이유).
@Riverpod(keepAlive: true)
class EditStyleSetting extends _$EditStyleSetting {
  @override
  FutureOr<String> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return normalizeEditStyle(await repo.getEditStyle());
  }

  Future<void> select(String choice) async {
    final value = normalizeEditStyle(choice);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setEditStyle(value);
    state = AsyncData(value);
  }
}

/// 분석 요청에 실을 style_profile — 모든 분석 경로(단건·기록 복원 폴백·
/// 재분석·일괄)가 이 함수로 만든다. 저장된 프로필은 바꾸지 않는다.
Future<Map<String, dynamic>?> resolveRequestStyleProfile(Ref ref) async =>
    (await resolveRequestStyle(ref)).profile;

/// [resolveRequestStyleProfile]과 같되 선택값도 함께 돌려준다 (결과 화면 표시용).
Future<({String choice, Map<String, dynamic>? profile})> resolveRequestStyle(
    Ref ref) async {
  var choice = kEditStyleAuto;
  try {
    choice = await ref.read(editStyleSettingProvider.future);
  } catch (_) {
    // 읽지 못하면 자동 — 지금까지와 같은 요청.
  }
  return (
    choice: choice,
    profile:
        buildRequestStyleProfile(ref.read(userStyleProfileProvider), choice),
  );
}

/// 보정 스타일 안내를 지금 띄워야 하면 true를 돌려주고 '안내함'으로 기록한다.
///
/// 한 번만 띄운다 — 사용자가 닫아도 다시 묻지 않고 자동(서버 기본)으로 간다.
Future<bool> claimEditStylePrompt(
  SettingsRepository repo, {
  required Map<String, dynamic>? profile,
  required String choice,
  bool styleAnalysisInProgress = false,
}) async {
  final prompted = await repo.isEditStylePrompted();
  final show = shouldPromptEditStyle(
    profile: profile,
    choice: choice,
    alreadyPrompted: prompted,
    styleAnalysisInProgress: styleAnalysisInProgress,
  );
  if (show) await repo.setEditStylePrompted();
  return show;
}
