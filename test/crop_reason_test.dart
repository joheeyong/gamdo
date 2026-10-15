import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/features/analysis/presentation/providers/transform_provider.dart';

void main() {
  test('서버가 남긴 크롭·비율 이유를 읽는다', () {
    const state = TransformState(autoEdits: {
      'suggested_crop': {'x': 0.1, 'y': 0.0, 'width': 0.7, 'height': 1.0},
      'crop_reason': ' 발 아래 바닥 여백을 줄였어요 ',
      'ratio_reason': '인스타그램이 받지 않는 비율이라 3:4로 맞췄어요',
    });
    expect(state.cropReason, '발 아래 바닥 여백을 줄였어요');
    expect(state.ratioReason, '인스타그램이 받지 않는 비율이라 3:4로 맞췄어요');
  });

  test('이유가 없거나 비었거나 문자열이 아니면 null (옛 기록 포함)', () {
    expect(const TransformState().cropReason, isNull);
    const state = TransformState(autoEdits: {'crop_reason': '  ', 'ratio_reason': 3});
    expect(state.cropReason, isNull);
    expect(state.ratioReason, isNull);
  });
}
