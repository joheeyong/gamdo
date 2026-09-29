import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  /// DioException에서 만들어졌다면 그 종류. 문자열 매칭보다 정확하다.
  final DioExceptionType? dioType;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.dioType,
  });

  /// DioException → ApiException. 타임아웃/연결 오류를 종류로 구분할 수 있다.
  factory ApiException.fromDio(DioException e) => ApiException(
        message: e.message ?? e.error?.toString() ?? 'Network error',
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        dioType: e.type,
      );

  static const _networkTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  // Dio 메시지는 'receiveTimeout', 'connectTimeout'처럼 대소문자가 섞여 있어
  // 소문자로 바꿔 비교한다.
  static const _networkMessageHints = [
    'socketexception',
    'connection refused',
    'network is unreachable',
    'timeout',
    'took longer than',
    'failed host lookup',
    'connection errored',
  ];

  /// 사용자에게 보여줄 친화적 에러 메시지.
  String get userMessage {
    // 네트워크 연결 문제 (statusCode 유무와 무관)
    if (_networkTypes.contains(dioType)) {
      return '인터넷 연결을 확인해 주세요';
    }
    final lower = message.toLowerCase();
    if (_networkMessageHints.any(lower.contains)) {
      return '인터넷 연결을 확인해 주세요';
    }
    // 서버가 바쁨 (분석 작업 대기열이 가득 참: 503 error_code busy)
    final body = data;
    if (body is Map && body['error_code'] == 'busy') {
      return '요청이 많아요. 잠시 후 다시 시도해 주세요';
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
