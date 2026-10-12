import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/theme/app_theme.dart';
import 'package:gamdo/features/analysis/presentation/screens/analysis_result_screen.dart';
import 'package:gamdo/features/analysis/presentation/widgets/photo_viewer.dart';
import 'package:gamdo/l10n/app_localizations.dart';

/// 1×1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
);

String _analysisJson({int? score, int? before}) => jsonEncode({
      'colorAnalysis': {
        'dominantColors': ['#AABBCC'],
        'colorTemperature': 'warm',
        'saturationLevel': 0.5,
        'brightnessLevel': 0.5,
        'colorHarmony': '유사색 조화',
        'paletteDescription': '따뜻한 색',
      },
      'compositionAnalysis': {'primaryTechnique': '삼분법', 'balanceScore': 0.7},
      'toneReport': {'overallMood': '차분함', 'styleCategory': '필름', 'narrative': '부드러움'},
      'feedCompatibility': ?score,
      'feedCompatibilityBefore': ?before,
    });

Future<void> _pump(WidgetTester tester, {String? before, String? after}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AnalysisResultScreen(
      analysisJson: _analysisJson(),
      imagePath: before,
      transformedImagePath: after,
    ),
  ));
  await tester.pump();
}

void main() {
  late Directory dir;
  late String beforePath;
  late String afterPath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ba_test');
    beforePath = '${dir.path}/before.png';
    afterPath = '${dir.path}/after.png';
    File(beforePath).writeAsBytesSync(_png);
    File(afterPath).writeAsBytesSync(_png);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('보정 후가 먼저 보이고, 넘기면 보정 전이 나온다', (tester) async {
    await _pump(tester, before: beforePath, after: afterPath);
    expect(find.text('보정 후'), findsOneWidget);
    expect(find.text('보정 전'), findsNothing);
    // 오른쪽으로 넘기면 이전 장(보정 전)
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('보정 전'), findsOneWidget);
    expect(find.text('보정 후'), findsNothing);
  });

  testWidgets('한 장이 화면 폭을 가득 채운다', (tester) async {
    await _pump(tester, before: beforePath, after: afterPath);
    final pageWidth = tester.getSize(find.byType(PageView)).width;
    final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(pageWidth, greaterThan(screenWidth * 0.85));
  });

  testWidgets('보정 후 사진이 없는 예전 기록은 원본 한 장만', (tester) async {
    await _pump(tester, before: beforePath, after: null);
    expect(find.text('원본'), findsOneWidget);
    expect(find.text('보정 전'), findsNothing);
    expect(find.text('보정 후'), findsNothing);
  });

  testWidgets('보정 후 카드를 누르면 뷰어가 After로 열린다', (tester) async {
    await _pump(tester, before: beforePath, after: afterPath);
    await tester.runAsync(() async {
      await tester.tap(find.text('보정 후'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    final viewer = tester.widget<PhotoViewerScreen>(find.byType(PhotoViewerScreen));
    expect(viewer.initialIndex, 1);
    expect(viewer.transformedBytes, isNotNull);
  });

  testWidgets('보정 전 카드를 누르면 뷰어가 Before로 열린다', (tester) async {
    await _pump(tester, before: beforePath, after: afterPath);
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('보정 전'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    final viewer = tester.widget<PhotoViewerScreen>(find.byType(PhotoViewerScreen));
    expect(viewer.initialIndex, 0);
  });
}
