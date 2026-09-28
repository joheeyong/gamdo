import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/features/analysis/presentation/providers/transform_provider.dart';
import 'package:gamdo/features/photo_upload/presentation/screens/photo_upload_screen.dart';

/// 취소 후에도 전역 상태가 loadingAutoTransform으로 남아 있던 상황을 재현한다.
class _StaleLoadingNotifier extends TransformNotifier {
  @override
  TransformState build() =>
      const TransformState(status: TransformStatus.loadingAutoTransform);
}

void main() {
  testWidgets('전역 상태가 분석 중으로 남아 있어도 업로드 화면이 터지지 않는다',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [transformProvider.overrideWith(_StaleLoadingNotifier.new)],
      child: const MaterialApp(home: PhotoUploadScreen()),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    // 사진을 고르기 전이므로 대기 화면이 아니라 업로드 뷰가 보여야 한다
    expect(find.text('사진을 선택하세요'),
        findsOneWidget);
  });
}
