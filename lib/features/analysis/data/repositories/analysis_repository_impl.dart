import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;

import '../../../../core/services/database.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/services/stored_path.dart';
import '../../domain/entities/analysis_job_progress.dart';
import '../../domain/entities/stored_transform.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../claude_datasource.dart';

/// [AnalysisRepository] 구현체 — GamdoAgentDatasource + ImageService + DB.
class AnalysisRepositoryImpl implements AnalysisRepository {
  final GamdoAgentDatasource _datasource;
  final ImageService _imageService;
  final AppDatabase _database;
  final DocumentsDirResolver _documentsDir;

  AnalysisRepositoryImpl({
    required GamdoAgentDatasource datasource,
    required ImageService imageService,
    required AppDatabase database,
    DocumentsDirResolver documentsDir = defaultDocumentsDir,
  })  : _datasource = datasource,
        _imageService = imageService,
        _database = database,
        _documentsDir = documentsDir;

  @override
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts = const [],
    List<Map<String, dynamic>> feeds = const [],
    List<Map<String, dynamic>> stories = const [],
    String userId = '',
  }) {
    return _datasource.analyzeUser(
      posts: posts,
      feeds: feeds,
      stories: stories,
      userId: userId,
    );
  }

  @override
  Future<({String analysisJson, String imagePath, Map<String, dynamic> fullResult})>
      analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
    bool reshapeEnabled = false,
    CancelToken? cancelToken,
  }) async {
    // 배치 등 기존 호출부 — 항상 새 기록을 만든다.
    final r = await analyzeAndTransformRecord(
      imageFile: imageFile,
      styleProfile: styleProfile,
      userId: userId,
      reshapeEnabled: reshapeEnabled,
      cancelToken: cancelToken,
    );
    return (
      analysisJson: r.analysisJson,
      imagePath: r.imagePath,
      fullResult: r.fullResult,
    );
  }

  @override
  Future<AnalyzeRecordResult> analyzeAndTransformRecord({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
    bool reshapeEnabled = false,
    CancelToken? cancelToken,
    int? recordId,
    void Function(AnalysisJobProgress progress)? onProgress,
  }) async {
    final processed = await _imageService.processImage(imageFile);

    final result = await _datasource.analyzeAndTransform(
      imageBase64: processed.base64,
      styleProfile: styleProfile ?? {},
      userId: userId,
      reshapeEnabled: reshapeEnabled,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    final analysis = result['analysis'] as Map<String, dynamic>? ?? {};
    final analysisJson = jsonEncode(analysis);
    // 기록에서 다시 열 때 AI 없이 apply-transform으로 같은 그림을 그리기 위한 값
    final transformJson = StoredTransform.fromServerResult(result).encode();

    final styleCategory =
        (analysis['toneReport']?['styleCategory'] as String?) ?? '분석완료';
    final colorTemp =
        (analysis['colorAnalysis']?['colorTemperature'] as String?) ?? 'neutral';
    final docsDir = await _documentsDir();

    // 기존 기록을 다시 분석하는 경우: 원본은 이미 앱 폴더에 있으므로 다시
    // 복사하지 않고 그 행을 갱신한다. 매번 새 행을 넣으면 기록이 중복된다.
    final existing =
        recordId == null ? null : await _database.getAnalysisById(recordId);

    final String savedImagePath;
    if (existing != null) {
      savedImagePath = resolveStoredPath(existing.imagePath, docsDir);
    } else {
      savedImagePath = p.join(
        docsDir,
        'photos',
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await Directory(p.dirname(savedImagePath)).create(recursive: true);
      await processed.file.copy(savedImagePath);
    }

    // 목록에 보여 줄 그림은 변형(after) 결과다. 사용자가 저장 버튼을 누르기
    // 전에도 "내가 뭘 만들었는지"가 보여야 하므로 여기서 바로 남긴다.
    final thumbnailPath = await _saveAfterThumbnail(
      result['image_base64'] as String?,
      docsDir,
    );

    // 요청이 끝난 뒤 취소됐다면(배치 화면을 나감 등) 기록을 남기지 않는다.
    // 기존 기록의 원본은 사용자의 기록이므로 지우지 않는다.
    if (cancelToken != null && cancelToken.isCancelled) {
      if (existing == null) await _deleteQuietly(savedImagePath);
      await _deleteQuietly(thumbnailPath);
      throw DioException.requestCancelled(
        requestOptions: RequestOptions(path: 'analyze-and-transform'),
        reason: cancelToken.cancelError?.error ?? 'cancelled',
      );
    }

    // iOS는 앱 업데이트마다 컨테이너 경로가 바뀌므로 DB에는 문서 디렉터리
    // 기준 상대 경로를 남긴다. 읽는 쪽(home/history 저장소)이 다시 절대
    // 경로로 바꾼다. 반환값은 지금 바로 쓰는 값이라 절대 경로 그대로 둔다.
    final storedThumb =
        thumbnailPath == null ? null : toStoredPath(thumbnailPath, docsDir);

    final int id;
    if (existing != null) {
      id = existing.id;
      await _database.updateAnalysisRecord(
        id,
        AnalysisRecordsCompanion(
          analysisJson: Value(analysisJson),
          styleCategory: Value(styleCategory),
          colorTemperature: Value(colorTemp),
          transformJson: Value(transformJson),
          // 새 썸네일을 못 만들었으면 이전 것을 그대로 둔다
          thumbnailPath:
              storedThumb == null ? const Value.absent() : Value(storedThumb),
        ),
      );
      final oldThumb = existing.thumbnailPath;
      if (thumbnailPath != null && oldThumb != null) {
        final oldAbs = resolveStoredPath(oldThumb, docsDir);
        if (!p.equals(oldAbs, thumbnailPath)) await _deleteQuietly(oldAbs);
      }
    } else {
      id = await _database.insertAnalysis(
        AnalysisRecordsCompanion.insert(
          imagePath: toStoredPath(savedImagePath, docsDir),
          analysisJson: analysisJson,
          styleCategory: styleCategory,
          colorTemperature: colorTemp,
          thumbnailPath: Value(storedThumb),
          transformJson: Value(transformJson),
        ),
      );
    }

    return (
      recordId: id,
      analysisJson: analysisJson,
      imagePath: savedImagePath,
      fullResult: result,
    );
  }

  @override
  Future<SavedAnalysis?> loadRecord(int recordId) async {
    final stored = await _database.getAnalysisById(recordId);
    if (stored == null) return null;
    final record = resolveRecordPaths(stored, await _documentsDir());
    return SavedAnalysis(
      id: record.id,
      imagePath: record.imagePath,
      thumbnailPath: record.thumbnailPath,
      analysisJson: record.analysisJson,
      transform: StoredTransform.tryDecode(record.transformJson),
    );
  }

  /// 변형 결과 base64를 썸네일 파일로 남기고 경로를 돌려준다.
  ///
  /// 실패해도 분석 자체는 성공이므로 null을 돌려 목록이 원본으로 폴백하게 둔다.
  Future<String?> _saveAfterThumbnail(String? imageBase64, String appDirPath) async {
    if (imageBase64 == null || imageBase64.isEmpty) return null;
    try {
      final bytes = base64Decode(imageBase64);
      final file = await _imageService.saveThumbnail(
        Uint8List.fromList(bytes),
        p.join(
          appDirPath,
          'photos',
          'after_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteQuietly(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // 정리 실패는 무시
    }
  }

  @override
  Future<List<String>> fetchReferenceImages(String userId) {
    return _datasource.fetchReferenceImages(userId);
  }
}
