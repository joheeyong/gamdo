import '../../../../core/services/database.dart';
import '../../domain/repositories/history_repository.dart';

/// [HistoryRepository] 구현체 — AppDatabase에 위임.
class HistoryRepositoryImpl implements HistoryRepository {
  final AppDatabase _database;

  HistoryRepositoryImpl({required AppDatabase database}) : _database = database;

  @override
  Stream<List<AnalysisRecord>> watchAll() {
    return _database.watchAllAnalyses();
  }

  @override
  Stream<List<AnalysisRecord>> watchByStyle(String style) {
    return _database.watchByStyle(style);
  }

  @override
  Stream<List<AnalysisRecord>> watchAllSortedByScore({bool ascending = false}) {
    return _database.watchAllAnalysesByScore(ascending: ascending);
  }

  @override
  Stream<List<AnalysisRecord>> watchByStyleSortedByScore(
    String style, {
    bool ascending = false,
  }) {
    return _database.watchByStyleSortedByScore(style, ascending: ascending);
  }

  @override
  Future<int> delete(int id) {
    return _database.deleteAnalysis(id);
  }
}
