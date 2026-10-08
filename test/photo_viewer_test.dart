import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/features/analysis/presentation/widgets/photo_viewer.dart';

// 1x1 투명 PNG
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  late File original;

  setUpAll(() {
    original = File('${Directory.systemTemp.createTempSync().path}/o.png')
      ..writeAsBytesSync(_png);
  });

  Future<void> pump(WidgetTester tester, {Uint8List? after, int index = 1}) {
    return tester.pumpWidget(
      MaterialApp(
        home: PhotoViewerScreen(
          originalImage: original,
          transformedBytes: after,
          initialIndex: index,
        ),
      ),
    );
  }

  bool showsAfter(WidgetTester tester) => find
      .byType(Image)
      .evaluate()
      .any((e) => (e.widget as Image).image is MemoryImage);

  TransformationController controller(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byType(InteractiveViewer))
      .transformationController!;

  testWidgets('After로 열리고 Before/After를 바꿔 볼 수 있다', (tester) async {
    await pump(tester, after: _png);
    expect(showsAfter(tester), isTrue);

    await tester.tap(find.text('Before'));
    await tester.pump();
    expect(showsAfter(tester), isFalse);

    await tester.tap(find.text('After'));
    await tester.pump();
    expect(showsAfter(tester), isTrue);
  });

  testWidgets('길게 누르는 동안만 원본을 보여 준다', (tester) async {
    await pump(tester, after: _png);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(InteractiveViewer)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(showsAfter(tester), isFalse);
    expect(find.text('Before (원본)'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(showsAfter(tester), isTrue);
  });

  testWidgets('확대한 상태에서는 가만히 눌렀다 끌어도 원본으로 바뀌지 않고 이동한다', (tester) async {
    await pump(tester, after: _png);
    final center = tester.getCenter(find.byType(InteractiveViewer));

    // 두 번 탭으로 확대
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(controller(tester).value.getMaxScaleOnAxis(), closeTo(2.5, 0.01));
    final before = controller(tester).value.getTranslation();

    // 손가락을 길게 대고 있다가(길게 누르기 시간 초과) 끈다
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    expect(showsAfter(tester), isTrue);
    expect(find.text('Before (원본)'), findsNothing);

    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(showsAfter(tester), isTrue);
    expect(find.text('Before (원본)'), findsNothing);
    final moved = controller(tester).value.getTranslation();
    expect(moved.x, greaterThan(before.x));
    expect(moved.y, greaterThan(before.y));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(showsAfter(tester), isTrue);
  });

  testWidgets('두 손가락으로 천천히 집어도 원본으로 바뀌지 않고 확대된다', (tester) async {
    await pump(tester, after: _png);
    final center = tester.getCenter(find.byType(InteractiveViewer));

    final first = await tester.startGesture(center - const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 200));
    final second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    // 두 손가락 모두 가만히 — 길게 누르기 시간을 넘긴다
    await tester.pump(const Duration(milliseconds: 600));
    expect(showsAfter(tester), isTrue);
    expect(find.text('Before (원본)'), findsNothing);

    for (var i = 0; i < 5; i++) {
      await first.moveBy(const Offset(-15, 0));
      await second.moveBy(const Offset(15, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(showsAfter(tester), isTrue);
    expect(controller(tester).value.getMaxScaleOnAxis(), greaterThan(1.5));

    await first.up();
    await second.up();
    await tester.pumpAndSettle();
  });

  testWidgets('두 번 탭하면 확대, 다시 두 번 탭하면 원래 크기', (tester) async {
    await pump(tester, after: _png);
    final center = tester.getCenter(find.byType(InteractiveViewer));

    Future<void> doubleTap() async {
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();
    }

    await doubleTap();
    expect(controller(tester).value.getMaxScaleOnAxis(), closeTo(2.5, 0.01));

    // 확대한 채로 Before로 바꿔도 확대 위치는 그대로
    await tester.tap(find.text('Before'));
    await tester.pump();
    expect(controller(tester).value.getMaxScaleOnAxis(), closeTo(2.5, 0.01));

    await doubleTap();
    expect(controller(tester).value.getMaxScaleOnAxis(), closeTo(1.0, 0.01));
  });

  testWidgets('변형 결과가 없으면 원본만, Before/After 선택은 숨긴다', (tester) async {
    await pump(tester, after: null);
    expect(showsAfter(tester), isFalse);
    expect(find.text('Before'), findsNothing);
    expect(find.text('두 손가락으로 확대 · 두 번 탭'), findsOneWidget);
  });

  testWidgets('닫기 버튼으로 돌아간다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => PhotoViewerScreen.open(
              context,
              originalImage: original,
              transformedBytes: _png,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewerScreen), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewerScreen), findsNothing);
  });
}
