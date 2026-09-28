import '../../../../core/services/database.dart';
import '../../../../core/services/stored_path.dart';
import '../../domain/repositories/home_repository.dart';

/// [HomeRepository] 구현체 — AppDatabase에 위임.
class HomeRepositoryImpl implements HomeRepository {
  final AppDatabase _database;
  final DocumentsDirResolver _documentsDir;

  HomeRepositoryImpl({
    required AppDatabase database,
    DocumentsDirResolver documentsDir = defaultDocumentsDir,
  })  : _database = database,
        _documentsDir = documentsDir;

  /// DB의 저장 경로를 지금 열 수 있는 절대 경로로 바꿔 내보낸다.
  @override
  Stream<List<AnalysisRecord>> watchRecentAnalyses() {
    return resolveRecordStream(_database.watchAllAnalyses(), _documentsDir);
  }
}
