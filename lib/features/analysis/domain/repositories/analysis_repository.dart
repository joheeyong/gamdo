import 'dart:io';

import 'package:dio/dio.dart';

import '../entities/analysis_job_progress.dart';
import '../entities/stored_transform.dart';

/// [AnalysisRepository.analyzeAndTransformRecord]의 결과 — 기록 id 포함.
typedef AnalyzeRecordResult = ({
  int recordId,
  String analysisJson,
  String imagePath,
  Map<String, dynamic> fullResult,
});

/// 기록에서 변형 화면을 다시 열 때 필요한 값. 경로는 지금 열 수 있는 절대 경로.
class SavedAnalysis {
  final int id;
  final String imagePath;
  final String? thumbnailPath;
  final String analysisJson;

  /// null이면 v3 이전 기록(또는 읽을 수 없는 값) — AI 분석을 다시 돌려야 한다.
  final StoredTransform? transform;

  const SavedAnalysis({
    required this.id,
    required this.imagePath,
    this.thumbnailPath,
    required this.analysisJson,
    this.transform,
  });
}

/// 사진 분석 저장소 인터페이스.
abstract class AnalysisRepository {
  /// 사용자 스타일 분석 (게시글/피드/스토리 기반)
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts,
    List<Map<String, dynamic>> feeds,
    List<Map<String, dynamic>> stories,
    String userId,
  });

  /// 사진 분석 + 변형을 한 번에 수행.
  ///
  /// [imagePath]는 원본이다. 목록에 보여 줄 변형본은 DB의 thumbnailPath에
  /// 저장되므로 반환하지 않는다.
  Future<({String analysisJson, String imagePath, Map<String, dynamic> fullResult})>
      analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId,
    bool reshapeEnabled,
    bool skinRetouchEnabled,
    CancelToken? cancelToken,
  });

  /// [analyzeAndTransform]과 같지만 기록 id를 함께 돌려준다.
  ///
  /// [recordId]가 있으면 새 행을 만들지 않고 그 기록을 갱신한다 — 원본은
  /// 다시 복사하지 않고, 썸네일만 새로 만들어 바꾼다 (다시 분석/재시도,
  /// transformJson이 없는 옛 기록 열기). 그 기록이 사라졌으면 새로 만든다.
  /// [onProgress]는 서버 작업의 단계(대기/분석/렌더링)와 경과 시간을 받는다.
  Future<AnalyzeRecordResult> analyzeAndTransformRecord({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId,
    bool reshapeEnabled,
    bool skinRetouchEnabled,
    CancelToken? cancelToken,
    int? recordId,
    void Function(AnalysisJobProgress progress)? onProgress,
  });

  /// 기록 하나를 읽는다. 없으면 null.
  Future<SavedAnalysis?> loadRecord(int recordId);

  /// 기록의 재현 정보(transformJson) 중 autoEdits만 바꾼다 ('추천 구도로
  /// 자르기' 등 사용자가 고른 기하 편집). 재현 정보가 없는 기록이면 그대로 둔다.
  Future<void> updateStoredAutoEdits(
      int recordId, Map<String, dynamic>? autoEdits);

  /// 사용자 대표 사진 base64 목록 조회
  Future<List<String>> fetchReferenceImages(String userId);
}
