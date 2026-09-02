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
}
