import '../../../../core/services/database.dart';

/// 기록 화면 저장소 인터페이스.
abstract class HistoryRepository {
  /// 전체 분석 기록 스트림.
  Stream<List<AnalysisRecord>> watchAll();

  /// 스타일별 분석 기록 스트림.
  Stream<List<AnalysisRecord>> watchByStyle(String style);

  /// 분석 기록 삭제.
  Future<int> delete(int id);
}
