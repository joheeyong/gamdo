import '../../../../core/services/database.dart';

/// 홈 화면 저장소 인터페이스.
abstract class HomeRepository {
  /// 최근 분석 기록 스트림 (실시간 감지).
  Stream<List<AnalysisRecord>> watchRecentAnalyses();
}
