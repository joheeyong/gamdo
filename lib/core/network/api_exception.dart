class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  /// 사용자에게 보여줄 친화적 에러 메시지.
  String get userMessage {
    // 메시지 기반 네트워크 연결 문제 (statusCode 유무와 무관)
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Network is unreachable') ||
        message.contains('timeout') ||
        message.contains('Failed host lookup')) {
      return '인터넷 연결을 확인해 주세요';
    }
    // 서버 에러 (5xx)
    if (statusCode != null && statusCode! >= 500) {
      return '서버에 문제가 발생했습니다. 잠시 후 다시 시도해 주세요';
    }
    // 인증 오류
    if (statusCode == 401 || statusCode == 403) {
      return '인증이 만료되었습니다. 다시 로그인해 주세요';
    }
    // 요청 제한
    if (statusCode == 429) {
      return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요';
    }
    // 잘못된 요청
    if (statusCode == 400) {
      return '잘못된 요청입니다. 다시 시도해 주세요';
    }
    // 리소스 없음
    if (statusCode == 404) {
      return '요청한 정보를 찾을 수 없습니다';
    }
    return '오류가 발생했습니다. 다시 시도해 주세요';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
