import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/app.dart';
import 'package:gamdo/features/settings/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // 온보딩 미완료 + Instagram 토큰 없음 → 스플래시 뒤 온보딩으로 간다.
    // 토큰이 없으면 Firebase를 건드리지 않는다.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('스플래시를 보여 준 뒤 온보딩으로 이동한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GamdoApp()));

    expect(find.text('감도'), findsOneWidget);

    // 스플래시는 2초 뒤 이동한다. 타이머를 흘려보내고 화면 전환을 끝낸다.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('사진, 감각으로 읽다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('저장된 다크 모드가 첫 프레임부터 적용된다', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [initialDarkModeProvider.overrideWithValue(true)],
      child: const GamdoApp(),
    ));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    // 스플래시 타이머가 남지 않도록 이동까지 마친다.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  test('loadSavedDarkMode는 저장값을 읽고 없으면 false', () async {
    SharedPreferences.setMockInitialValues({'dark_mode': true});
    expect(await loadSavedDarkMode(), isTrue);
    SharedPreferences.setMockInitialValues({});
    expect(await loadSavedDarkMode(), isFalse);
  });
}
