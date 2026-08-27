class ApiConstants {
  ApiConstants._();

  static const String defaultProxyUrl = 'http://192.168.0.46:8000'; // 로컬 개발 서버
  static const int maxImageSize = 1568;
  static const int fallbackImageSize = 800;
  static const int jpegQuality = 85;
  static const int fallbackJpegQuality = 60;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
}
