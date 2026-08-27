class ApiConstants {
  ApiConstants._();

  static const String defaultProxyUrl = 'https://pins-held-massachusetts-publish.trycloudflare.com'; // Cloudflare 터널
  static const int maxImageSize = 1568;
  static const int fallbackImageSize = 800;
  static const int jpegQuality = 85;
  static const int fallbackJpegQuality = 60;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
}
