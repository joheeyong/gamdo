import '../entities/instagram_auth.dart';

/// 인증 저장소 인터페이스.
abstract class AuthRepository {
  /// 저장된 토큰 복원 → InstagramAuth 반환.
  Future<InstagramAuth> restoreSession();

  /// 서버 세션 확인/재발급 + Firebase Auth 로그인 (네트워크).
  /// 실패는 조용히 넘기고, Instagram 토큰이 무효일 때만 [SessionValidation.loggedOut].
  Future<SessionValidation> validateSession();

  /// Instagram OAuth 로그인 → 토큰 교환 → 저장 → InstagramAuth 반환.
  Future<InstagramAuth> login();

  /// Instagram 연결 해제.
  Future<void> logout();
}

/// [AuthRepository.validateSession] 결과.
enum SessionValidation {
  /// Instagram 연결 유지 (세션 발급 여부와 무관).
  connected,

  /// 연결 유지 + Firebase Auth 로그인 완료.
  firebaseSignedIn,

  /// Instagram 토큰이 없거나 무효 — 재연결 필요.
  loggedOut,
}
