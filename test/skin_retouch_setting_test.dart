import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/services/storage_service.dart';
import 'package:gamdo/features/settings/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('피부 보정은 저장된 값이 없으면 켜져 있다', () async {
    expect(await StorageService().isSkinRetouchEnabled(), isTrue);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(skinRetouchEnabledSettingProvider.future),
        isTrue);
  });

  test('토글하면 skin_retouch_enabled에 저장되고 다시 시작해도 유지된다', () async {
    var container = ProviderContainer();
    await container.read(skinRetouchEnabledSettingProvider.future);
    await container.read(skinRetouchEnabledSettingProvider.notifier).toggle();
    expect(container.read(skinRetouchEnabledSettingProvider).value, isFalse);
    container.dispose();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('skin_retouch_enabled'), isFalse);
    // 얼굴/체형 보정 값과 섞이지 않는다
    expect(prefs.getBool('reshape_enabled'), isNull);

    container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(skinRetouchEnabledSettingProvider.future),
        isFalse);

    await container.read(skinRetouchEnabledSettingProvider.notifier).toggle();
    expect(prefs.getBool('skin_retouch_enabled'), isTrue);
    expect(container.read(skinRetouchEnabledSettingProvider).value, isTrue);
  });
}
