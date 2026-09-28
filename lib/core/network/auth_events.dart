import 'dart:async';

/// 로그인 상태가 앱 바깥 요인으로 바뀌었을 때의 사유.
enum AuthEventType {
  /// Instagram 토큰이 무효/만료(60일)되어 재연결이 필요하다.
  instagramTokenInvalid,
}

/// 네트워크 계층(인터셉터·세션 서비스) → 인증 상태(Notifier) 알림 채널.
///
/// 인터셉터가 auth provider를 직접 참조하면 dio ↔ auth 사이에 순환 의존이
/// 생긴다. 대신 이 전역 브로드캐스트 스트림에 이벤트를 흘리고,
/// InstagramAuthNotifier가 구독한다.
class AuthEvents {
  AuthEvents._();

  static final StreamController<AuthEventType> _controller =
      StreamController<AuthEventType>.broadcast();

  static Stream<AuthEventType> get stream => _controller.stream;

  static void emit(AuthEventType event) => _controller.add(event);
}
