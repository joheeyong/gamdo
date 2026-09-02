import '../../../../core/services/database.dart';
import '../../domain/repositories/home_repository.dart';

/// [HomeRepository] 구현체 — AppDatabase에 위임.
class HomeRepositoryImpl implements HomeRepository {
  final AppDatabase _database;

  HomeRepositoryImpl({required AppDatabase database}) : _database = database;

  @override
  Stream<List<AnalysisRecord>> watchRecentAnalyses() {
    return _database.watchAllAnalyses();
  }
}
