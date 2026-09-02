import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../entities/transform_params.dart';

/// 변형 결과 — 서버 응답에서 이미지 바이트와 파라미터를 포함.
class TransformResult {
  final Uint8List imageBytes;
  final TransformParams params;

  const TransformResult({
    required this.imageBytes,
    required this.params,
  });
}

/// 사진 변형 저장소 인터페이스.
abstract class TransformRepository {
  /// AI 분석 기반 자동 변형
  Future<TransformResult> autoTransform({
    required File imageFile,
    required Map<String, dynamic> analysis,
    Map<String, dynamic>? styleProfile,
  });

  /// 슬라이더 값으로 수동 변형
  Future<Map<String, dynamic>> applyManualTransform({
    File? imageFile,
    String? imageBase64,
    bool preview,
    required TransformParams params,
    Map<String, dynamic>? autoEdits,
    Map<String, dynamic>? regionParams,
    CancelToken? cancelToken,
  });
}
