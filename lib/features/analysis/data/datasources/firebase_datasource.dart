import '../../../../core/services/firebase_service.dart';

/// Firebase RTDB 데이터소스 — FirebaseService에 위임.
///
/// 현재는 core의 FirebaseService를 그대로 사용하며,
/// 향후 feature-specific 로직이 추가되면 이 클래스에서 확장.
class FirebaseDatasource {
  final FirebaseService _firebaseService;

  FirebaseDatasource(this._firebaseService);

  Future<void> saveStyleProfile({
    required String userId,
    required Map<String, dynamic> styleProfile,
    String? summary,
    List<dynamic>? recommendations,
  }) =>
      _firebaseService.saveStyleProfile(
        userId: userId,
        styleProfile: styleProfile,
        summary: summary,
        recommendations: recommendations,
      );

  Future<Map<String, dynamic>?> getStyleProfile(String userId) =>
      _firebaseService.getStyleProfile(userId);

  Future<void> deleteStyleProfile(String userId) =>
      _firebaseService.deleteStyleProfile(userId);

  Future<void> saveFeedback({
    required String userId,
    required Map<String, double> delta,
  }) =>
      _firebaseService.saveFeedback(userId: userId, delta: delta);

  Future<List<Map<String, double>>> loadFeedbackHistory(String userId) =>
      _firebaseService.loadFeedbackHistory(userId);

  Future<void> updateTargetParams({
    required String userId,
    required Map<String, double> avgDelta,
    double learningRate = 0.3,
  }) =>
      _firebaseService.updateTargetParams(
        userId: userId,
        avgDelta: avgDelta,
        learningRate: learningRate,
      );
}
