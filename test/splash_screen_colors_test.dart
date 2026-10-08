import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/theme/app_colors.dart';
import 'package:gamdo/core/theme/app_theme.dart';
import 'package:gamdo/features/onboarding/presentation/screens/splash_screen.dart';

/// 스플래시는 앱 테마 설정이 아니라 시스템 밝기를 따라야 네이티브 실행 화면과 색이 이어진다.
void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    required ThemeData appTheme,
    required Brightness system,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: MediaQuery(
            data: MediaQueryData(platformBrightness: system),
            child: const SplashScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// 스플래시를 내리고 2초 네비게이션 타이머를 소진시킨다 (unmounted라 이동하지 않음).
  Future<void> tearDownSplash(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  }

  Color scaffoldBg(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;

  Color wordmarkColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('감도')).style!.color!;

  SystemUiOverlayStyle overlay(WidgetTester tester) => tester
      .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first)
      .value;

  testWidgets('system dark + app light theme -> darkroom splash',
      (tester) async {
    await pumpSplash(tester, appTheme: AppTheme.light, system: Brightness.dark);

    expect(scaffoldBg(tester), AppColors.backgroundDark);
    expect(wordmarkColor(tester), AppColors.textPrimaryDark);
    expect(overlay(tester).statusBarIconBrightness, Brightness.light);

    await tearDownSplash(tester);
  });

  testWidgets('system light + app dark theme -> paper splash', (tester) async {
    await pumpSplash(tester, appTheme: AppTheme.dark, system: Brightness.light);

    expect(scaffoldBg(tester), AppColors.backgroundLight);
    expect(wordmarkColor(tester), AppColors.textPrimaryLight);
    expect(overlay(tester).statusBarIconBrightness, Brightness.dark);

    await tearDownSplash(tester);
  });
}
