/// Instagram API with Instagram Login 상수.
///
/// Meta Developer Console에서 앱 생성 후 실제 값으로 교체해야 합니다.
class InstagramConstants {
  InstagramConstants._();

  /// Meta Developer Console에서 발급받은 Instagram Client ID.
  /// (Facebook 앱 ID와 다름 — Instagram 비즈니스 로그인 설정에서 확인)
  static const String clientId = '897959926379711';

  /// 요청할 권한 범위.
  static const String scope = 'instagram_business_basic';

  /// Instagram OAuth authorize URL.
  static const String authorizeUrl =
      'https://www.instagram.com/oauth/authorize';

  /// Instagram Graph API base URL.
  static const String graphApiBaseUrl = 'https://graph.instagram.com';

  /// 미디어 조회 시 요청할 필드.
  static const String mediaFields =
      'id,caption,media_type,media_url,thumbnail_url,timestamp,permalink';

  /// OAuth callback scheme (flutter_web_auth_2에 전달).
  static const String callbackScheme = 'gamdo';

  /// OAuth redirect_uri. Meta 앱 설정의 '유효한 OAuth 리디렉션 URI'에 똑같이
  /// 등록돼 있어야 한다.
  ///
  /// 기본은 서버 콜백(ngrok)이다. Firebase Hosting의 콜백 페이지를 배포하고
  /// Meta에 등록한 뒤에는 빌드할 때 아래처럼 바꾼다 (ngrok 무료 도메인은 브라우저에
  /// 경고 화면을 띄워 로그인 중간에 끼어든다):
  ///   --dart-define=INSTAGRAM_REDIRECT_URI=https://gamdo-app-2026.web.app/oauth/instagram/
  /// 비어 있으면 '<서버 주소>/api/instagram/callback'을 쓴다.
  static const String redirectUriOverride =
      String.fromEnvironment('INSTAGRAM_REDIRECT_URI');

  /// 개인정보처리방침 (Firebase Hosting).
  static const String privacyPolicyUrl = 'https://gamdo-app-2026.web.app/privacy.html';

  /// 데이터 삭제 안내 (Firebase Hosting). Meta 앱 설정의 '데이터 삭제 안내 URL'.
  static const String dataDeletionUrl = 'https://gamdo-app-2026.web.app/data-deletion.html';
}
