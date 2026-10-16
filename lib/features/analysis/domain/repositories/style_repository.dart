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
}
