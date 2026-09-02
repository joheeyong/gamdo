class ApiConstants {
  ApiConstants._();

  static const String defaultProxyUrl = 'https://cinderella-vitiable-noncapitalistically.ngrok-free.dev'; // ngrok HTTPS 터널
  static const int maxImageSize = 1568;
  static const int fallbackImageSize = 800;
  static const int jpegQuality = 85;
  static const int fallbackJpegQuality = 60;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  // 프록시 미리보기용 (슬라이더 조작 시 저해상도로 빠른 응답)
  static const int previewImageSize = 800;
  static const int previewJpegQuality = 70;
}
