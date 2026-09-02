import 'dart:typed_data';

import 'transform_params.dart';

/// 변형 결과 — 변형된 이미지 바이트 + 적용된 파라미터.
class TransformResult {
  final Uint8List imageBytes;
  final TransformParams params;

  const TransformResult({
    required this.imageBytes,
    required this.params,
  });
}
