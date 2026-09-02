import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/theme/app_theme.dart';
import 'package:gamdo/core/theme/app_typography.dart';
import 'package:gamdo/core/widgets/insta_ui.dart';

void main() {
  Widget host(Widget child, ThemeData theme) => MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      );

  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    testWidgets('insta kit renders (${entry.key})', (tester) async {
      await tester.pumpWidget(host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const InstaSectionLabel('설정'),
            const InstaHairline(),
            InstaPill(label: '미니멀', selected: true, onTap: () {}),
            InstaPill(label: '빈티지', selected: false, onTap: () {}),
            const InstaSettingRow(icon: Icons.dark_mode, title: '다크 모드', subtitle: '설명'),
            const InstaStat(value: '12', label: '분석'),
            InstaSecondaryButton(label: '편집', onPressed: () {}),
            const GradientText('감도'),
            const GradientIcon(Icons.auto_awesome),
          ],
        ),
        entry.value,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('미니멀'), findsOneWidget);
    });

    testWidgets('confirm dialog + sheet + toast (${entry.key})', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        theme: entry.value,
        home: Scaffold(body: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        })),
      ));

      final future = showInstaConfirm(ctx,
          title: '삭제', message: '삭제할까요?', confirmLabel: '삭제', isDestructive: true);
      await tester.pumpAndSettle();
      expect(find.text('삭제할까요?'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(await future, isFalse);

      showInstaSheet(ctx, title: '정렬', actions: [
        InstaSheetAction(icon: Icons.delete, label: '삭제', isDestructive: true, onTap: () {}),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('정렬'), findsOneWidget);
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      showInstaToast(ctx, '저장되었습니다', icon: Icons.check);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('저장되었습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('타이포 스케일이 인스타그램 기준으로 적용된다', (tester) async {
    late TextTheme t;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(builder: (c) {
        t = Theme.of(c).textTheme;
        return const SizedBox();
      }),
    ));
    // 본문 14px / 줄 간격 1.4 — 인스타그램 캡션 기준
    expect(t.bodyMedium!.fontSize, 14);
    expect(t.bodyMedium!.height, 1.4);
    // 큰 제목은 자간을 음수로 조인다
    expect(t.displaySmall!.letterSpacing, lessThan(0));
    expect(t.titleMedium!.fontWeight, FontWeight.w600);
    expect(t.bodyMedium!.fontFamily, AppTypography.fontFamily);
  });

  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    testWidgets('입력 필드가 테마 스타일로 렌더된다 (${entry.key})', (tester) async {
      await tester.pumpWidget(host(
        TextField(
          style: AppTypography.input,
          controller: TextEditingController(text: '감성적'),
          decoration: const InputDecoration(hintText: '예: 따뜻한, 차분한'),
        ),
        entry.value,
      ));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.style!.fontSize, 14);

      final deco = Theme.of(tester.element(find.byType(TextField)))
          .inputDecorationTheme;
      expect(deco.filled, isTrue);
      expect(deco.hintStyle!.fontSize, 14);
      final border = deco.enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(6));

      await tester.enterText(find.byType(TextField), '차분한');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
