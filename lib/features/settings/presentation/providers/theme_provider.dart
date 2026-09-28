import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 시작 시 SharedPreferences에서 읽어 둔 다크 모드 값.
///
/// main()이 runApp 전에 읽어 override한다. 첫 프레임부터 저장된 테마로
/// 그려야 라이트→다크 깜빡임이 없다. override가 없으면(테스트 등) 라이트.
final initialDarkModeProvider = Provider<bool>((ref) => false);

/// SharedPreferences의 다크 모드 값을 읽는다. 실패하면 false.
Future<bool> loadSavedDarkMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  } catch (_) {
    return false;
  }
}

class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialDarkModeProvider);

  Future<void> init() async {
    state = await loadSavedDarkMode();
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', state);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(() {
  return ThemeModeNotifier();
});
