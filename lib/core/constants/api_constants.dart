class ApiConstants {
  ApiConstants._();

  static const String defaultProxyUrl = 'https://cinderella-vitiable-noncapitalistically.ngrok-free.dev'; // ngrok HTTPS 터널

  /// 저장된 proxy_url을 실제로 쓸 URL로 바꾼다.
  /// 없거나 빈 문자열(공백뿐 포함)이면 [defaultProxyUrl].
  /// 설정 화면에서 값을 지우면 ""가 저장되므로 `??`만으로는 부족하다.
  static String resolveProxyUrl(String? saved) {
    if (saved == null || saved.trim().isEmpty) return defaultProxyUrl;
    return saved;
  }
  // 업로드 해상도 상한. 1568은 Claude 비전의 유효 상한에서 온 값이었는데,
  // 이제 분석용 사본은 서버가 따로 1024로 줄이므로 여기를 낮게 둘 이유가 없다.
  // 12MP 아이폰 사진이 1.8MP로 잘려 픽셀의 85%를 잃고 있었고,
  // 4:5로 크롭하면 941x1176이 되어 인스타 권장(1080x1350)에도 못 미쳤다.
  // 2560이면 크롭 후에도 권장치를 넘고, 서버 처리 시간은 +0.3초에 그친다.
  static const int maxImageSize = 2560;
  static const int fallbackImageSize = 800;
  // 저장본은 앱(업로드)과 서버(응답)에서 두 번 JPEG를 거친다.
  // 세대 손실을 줄이려 두 단계 모두 품질을 올렸다.
  static const int jpegQuality = 92;
  static const int fallbackJpegQuality = 60;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  // 프록시 미리보기용 (슬라이더 조작 시 저해상도로 빠른 응답)
  static const int previewImageSize = 800;
  static const int previewJpegQuality = 70;

  // 홈·기록 목록에 뿌리는 변형본 썸네일. 목록은 한 화면에 수십 장을 그리므로
  // 원본 해상도를 그대로 디코딩하면 스크롤이 끊긴다. 1080이면 전체 화면으로
  // 띄워도 흐리지 않고, 한 장이 200KB 안쪽이라 저장 공간도 부담이 없다.
  static const int thumbnailImageSize = 1080;
  static const int thumbnailJpegQuality = 85;
}
