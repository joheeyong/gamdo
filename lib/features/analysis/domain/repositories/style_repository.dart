/// 스타일 프로필 저장소 인터페이스 — Firebase RTDB CRUD.
abstract class StyleRepository {
  /// 스타일 프로필 저장
  Future<void> saveStyleProfile({
    required String userId,
    required Map<String, dynamic> styleProfile,
    String? summary,
    List<dynamic>? recommendations,
  });

  /// 스타일 프로필 조회
  Future<Map<String, dynamic>?> getStyleProfile(String userId);

  /// 스타일 프로필 삭제
  Future<void> deleteStyleProfile(String userId);

  /// 사용자 피드백(슬라이더 delta) 저장
  Future<void> saveFeedback({
    required String userId,
    required Map<String, double> delta,
  });

  /// 누적 피드백 히스토리 로드
  Future<List<Map<String, double>>> loadFeedbackHistory(String userId);

  /// 누적 피드백 평균으로 targetParams 업데이트
  Future<void> updateTargetParams({
    required String userId,
    required Map<String, double> avgDelta,
    double learningRate,
  });
}
