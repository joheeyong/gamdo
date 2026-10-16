import 'dart:io';

import 'package:dio/dio.dart';

import '../entities/transform_params.dart';

/// 사진 변형 저장소 인터페이스.
abstract class TransformRepository {
  /// 슬라이더 값으로 수동 변형
  Future<Map<String, dynamic>> applyManualTransform({
    File? imageFile,
    String? imageBase64,
    bool preview,
    required TransformParams params,
    Map<String, dynamic>? autoEdits,
    Map<String, dynamic>? regionParams,
    List<dynamic>? toneCurvePoints,
    CancelToken? cancelToken,
  });
}
