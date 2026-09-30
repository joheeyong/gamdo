import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/providers/style_profile_provider.dart';
import 'package:gamdo/core/services/storage_service.dart';
import 'package:gamdo/features/settings/presentation/providers/settings_provider.dart';
import 'package:gamdo/features/settings/presentation/widgets/edit_style_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('buildRequestStyleProfile (계약)', () {
    test('자동 + 프로필 없음 → null (서버 기본 레시피)', () {
      expect(buildRequestStyleProfile(null, kEditStyleAuto), isNull);
    });

    test('자동 + 프로필 → 같은 프로필 그대로', () {
      final profile = <String, dynamic>{'trendCategory': 'warm_film', 'x': 1};
      expect(buildRequestStyleProfile(profile, kEditStyleAuto), same(profile));
    });

    test('직접 선택 + 프로필 없음 → trendCategory·styleSource만', () {
      expect(buildRequestStyleProfile(null, 'korean_gamsung'),
          {'trendCategory': 'korean_gamsung', 'styleSource': 'manual'});
    });

    test('직접 선택 + 프로필 → 복사본의 trendCategory만 바꾸고 원본은 그대로', () {
      final profile = <String, dynamic>{
        'trendCategory': 'warm_film',
        'primaryStyle': '필름',
        'colorPreference': {'preferredTones': 'warm'},
      };
      final out = buildRequestStyleProfile(profile, 'bw_grain')!;
      expect(out, {
        'trendCategory': 'bw_grain',
        'primaryStyle': '필름',
        'colorPreference': {'preferredTones': 'warm'},
        'styleSource': 'manual',
      });
      expect(identical(out, profile), isFalse);
      expect(profile, {
        'trendCategory': 'warm_film',
        'primaryStyle': '필름',
        'colorPreference': {'preferredTones': 'warm'},
      });
    });

    test('모르는 선택값은 자동으로 취급한다', () {
      final profile = <String, dynamic>{'trendCategory': 'warm_film'};
      expect(buildRequestStyleProfile(profile, 'nope'), same(profile));
      expect(normalizeEditStyle('nope'), kEditStyleAuto);
      expect(normalizeEditStyle(null), kEditStyleAuto);
    });

    test('9가지 스타일 id가 계약과 같다', () {
      expect(kEditStyles.map((s) => s.id), [
        'warm_film',
        'korean_gamsung',
        'cinematic_moody',
        'golden_hour',
        'clean_minimal',
        'bright_airy',
        'flash_digicam',
        'soft_pastel',
        'bw_grain',
      ]);
    });
  });

  group('보정 스타일 설정', () {
    test('저장값이 없으면 자동', () async {
      expect(await StorageService().getEditStyle(), isNull);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(await c.read(editStyleSettingProvider.future), kEditStyleAuto);
    });

    test('선택하면 edit_style에 저장되고 다시 시작해도 유지된다', () async {
      var c = ProviderContainer();
      await c.read(editStyleSettingProvider.future);
      await c.read(editStyleSettingProvider.notifier).select('golden_hour');
      expect(c.read(editStyleSettingProvider).value, 'golden_hour');
      c.dispose();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('edit_style'), 'golden_hour');

      c = ProviderContainer();
      addTearDown(c.dispose);
      expect(await c.read(editStyleSettingProvider.future), 'golden_hour');

      await c.read(editStyleSettingProvider.notifier).select(kEditStyleAuto);
      expect(prefs.getString('edit_style'), kEditStyleAuto);
    });

    test('손상된 저장값은 자동으로 읽는다', () async {
      SharedPreferences.setMockInitialValues({'edit_style': 'legacy_x'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(await c.read(editStyleSettingProvider.future), kEditStyleAuto);
    });

    test('resolveRequestStyleProfile은 저장된 프로필을 바꾸지 않는다', () async {
      SharedPreferences.setMockInitialValues({'edit_style': 'clean_minimal'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final stored = <String, dynamic>{'trendCategory': 'warm_film'};
      c.read(userStyleProfileProvider.notifier).state = stored;

      final p = Provider((ref) => ref);
      final out = await resolveRequestStyleProfile(c.read(p));
      expect(out, {'trendCategory': 'clean_minimal', 'styleSource': 'manual'});
      expect(c.read(userStyleProfileProvider), same(stored));
      expect(stored, {'trendCategory': 'warm_film'});
    });
  });

  group('한 번만 뜨는 스타일 선택 안내', () {
    test('프로필 없음 + 자동 + 처음 → 띄운다', () {
      expect(
        shouldPromptEditStyle(
            profile: null, choice: kEditStyleAuto, alreadyPrompted: false),
        isTrue,
      );
    });

    test('프로필이 있거나, 이미 골랐거나, 이미 안내했거나, 분석 중이면 띄우지 않는다',
        () {
      expect(
        shouldPromptEditStyle(
            profile: const {'trendCategory': 'warm_film'},
            choice: kEditStyleAuto,
            alreadyPrompted: false),
        isFalse,
      );
      expect(
        shouldPromptEditStyle(
            profile: null, choice: 'warm_film', alreadyPrompted: false),
        isFalse,
      );
      expect(
        shouldPromptEditStyle(
            profile: null, choice: kEditStyleAuto, alreadyPrompted: true),
        isFalse,
      );
      expect(
        shouldPromptEditStyle(
            profile: null,
            choice: kEditStyleAuto,
            alreadyPrompted: false,
            styleAnalysisInProgress: true),
        isFalse,
      );
    });

    test('claimEditStylePrompt는 처음 한 번만 true — 닫아도 다시 묻지 않는다',
        () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final repo = c.read(settingsRepositoryProvider);

      expect(
          await claimEditStylePrompt(repo,
              profile: null, choice: kEditStyleAuto),
          isTrue);
      expect(
          await claimEditStylePrompt(repo,
              profile: null, choice: kEditStyleAuto),
          isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('edit_style_prompted'), isTrue);
    });

    test('프로필이 있거나 스타일을 골랐으면 안내하지 않고 기록도 남기지 않는다',
        () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final repo = c.read(settingsRepositoryProvider);

      expect(
          await claimEditStylePrompt(repo,
              profile: const {'trendCategory': 'warm_film'},
              choice: kEditStyleAuto),
          isFalse);
      expect(
          await claimEditStylePrompt(repo,
              profile: null, choice: 'soft_pastel'),
          isFalse);
      expect(
          await claimEditStylePrompt(repo,
              profile: null,
              choice: kEditStyleAuto,
              styleAnalysisInProgress: true),
          isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('edit_style_prompted'), isNull);
    });
  });

  testWidgets('선택 시트는 자동 + 9가지 스타일을 보여 주고 고른 값을 돌려준다',
      (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showEditStylePicker(context, current: 'auto');
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(kEditStyleAutoName), findsOneWidget);
    expect(find.text('웜 필름'), findsOneWidget);
    expect(find.text('필름 그레인·웜톤·바랜 검정'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('흑백 그레인'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('흑백 그레인'));
    await tester.pumpAndSettle();
    expect(picked, 'bw_grain');
  });
}
