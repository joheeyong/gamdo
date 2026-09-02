import '../entities/instagram_auth.dart';

/// 인증 저장소 인터페이스.
abstract class AuthRepository {
  /// 저장된 토큰 복원 → InstagramAuth 반환.
  Future<InstagramAuth> restoreSession();

  /// Instagram OAuth 로그인 → 토큰 교환 → 저장 → InstagramAuth 반환.
  Future<InstagramAuth> login();

  /// Instagram 연결 해제.
  Future<void> logout();
}
