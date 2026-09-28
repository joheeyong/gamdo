import 'dart:io';

import '../../../../core/services/database.dart';
import '../../../../core/services/stored_path.dart';
import '../../domain/repositories/history_repository.dart';

/// [HistoryRepository] 구현체 — AppDatabase에 위임.
class HistoryRepositoryImpl implements HistoryRepository {
  final AppDatabase _database;
  final DocumentsDirResolver _documentsDir;

  HistoryRepositoryImpl({
    required AppDatabase database,
    DocumentsDirResolver documentsDir = defaultDocumentsDir,
  })  : _database = database,
        _documentsDir = documentsDir;

  // DB에는 문서 디렉터리 기준 상대 경로(또는 예전 절대 경로)가 있으므로
  // 화면에 넘기기 전에 지금 열 수 있는 절대 경로로 바꾼다.
  @override
  Stream<List<AnalysisRecord>> watchAll() {
    return resolveRecordStream(_database.watchAllAnalyses(), _documentsDir);
  }

  @override
  Stream<List<AnalysisRecord>> watchByStyle(String style) {
    return resolveRecordStream(_database.watchByStyle(style), _documentsDir);
  }

  @override
  Future<int> delete(int id) async {
    // 행만 지우면 원본과 변형본이 앱 저장소에 계속 쌓인다.
    final stored = await _database.getAnalysisById(id);
    final deleted = await _database.deleteAnalysis(id);
    if (stored != null) {
      final record = resolveRecordPaths(stored, await _documentsDir());
      await _deleteFile(record.imagePath);
      await _deleteFile(record.thumbnailPath);
    }
    return deleted;
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // 파일 정리 실패는 삭제 자체를 되돌릴 이유가 아니다
    }
  }
}
