import 'dart:io';

import 'package:dio/dio.dart';

/// 사진 분석 저장소 인터페이스.
abstract class AnalysisRepository {
  /// 사용자 스타일 분석 (게시글/피드/스토리 기반)
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts,
    List<Map<String, dynamic>> feeds,
    List<Map<String, dynamic>> stories,
    String userId,
  });

  /// 사진 분석 + 변형을 한 번에 수행
  Future<({String analysisJson, String imagePath, Map<String, dynamic> fullResult})>
      analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId,
    bool reshapeEnabled,
    CancelToken? cancelToken,
  });

  /// 사용자 대표 사진 base64 목록 조회
  Future<List<String>> fetchReferenceImages(String userId);
}
