/// 분석 기록 도메인 엔티티 — Drift 테이블의 도메인 대응.
class AnalysisRecordEntity {
  final int id;
  final String imagePath;
  final String? thumbnailPath;
  final String analysisJson;
  final int overallScore;
  final String styleCategory;
  final String colorTemperature;
  final DateTime createdAt;

  const AnalysisRecordEntity({
    required this.id,
    required this.imagePath,
    this.thumbnailPath,
    required this.analysisJson,
    required this.overallScore,
    required this.styleCategory,
    required this.colorTemperature,
    required this.createdAt,
  });
}
