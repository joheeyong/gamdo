class ApiConstants {
  ApiConstants._();

  static const String defaultProxyUrl = 'https://gamdo-proxy.your-worker.workers.dev';
  static const String analysisEndpoint = '/api/analyze';
  static const String claudeModel = 'claude-sonnet-4-20250514';
  static const int maxImageSize = 1568;
  static const int fallbackImageSize = 800;
  static const int jpegQuality = 85;
  static const int fallbackJpegQuality = 60;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
}
