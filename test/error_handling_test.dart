import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/constants/api_constants.dart';
import 'package:gamdo/core/network/api_exception.dart';
import 'package:gamdo/core/services/firebase_service.dart';
import 'package:gamdo/features/analysis/presentation/providers/analysis_provider.dart';
import 'package:gamdo/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('ApiException.userMessage', () {
    const network = '인터넷 연결을 확인해 주세요';

    test('응답 대기 초과(receiveTimeout)는 연결 문제가 아니라 처리 지연으로 안내한다', () {
      final e = DioException.receiveTimeout(
        timeout: const Duration(seconds: 120),
        requestOptions: RequestOptions(),
      );
      // 예전 방식: 메시지만 넘기면 종류를 몰라 네트워크 문구로 폴백한다
      expect(ApiException(message: e.message!).userMessage, network);
      // 새 방식: 종류로 판단
      expect(ApiException.fromDio(e).userMessage,
          ApiException.slowResponseMessage);
    });

    test('서버가 준 사용자용 문장(userFacing)은 그대로 보여 준다', () {
      const e = ApiException(
        message: '사진 분석에 실패했습니다. 잠시 후 다시 시도해 주세요.',
        statusCode: 200,
        userFacing: true,
      );
      expect(e.userMessage, '사진 분석에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      // 빈 문장이면 일반 문구
      expect(const ApiException(message: ' ', userFacing: true).userMessage,
          contains('오류가 발생했습니다'));
    });

    test('connectionTimeout / connectionError도 네트워크 문제', () {
      for (final e in [
        DioException.connectionTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: RequestOptions()),
        DioException.connectionError(
            requestOptions: RequestOptions(), reason: 'x'),
      ]) {
        expect(ApiException.fromDio(e).userMessage, network);
      }
    });

    test('상태 코드 기반 메시지는 그대로', () {
      expect(const ApiException(message: 'x', statusCode: 500).userMessage,
          contains('서버'));
      expect(const ApiException(message: 'x', statusCode: 429).userMessage,
          contains('요청이 너무 많습니다'));
    });
  });

  group('ApiConstants.resolveProxyUrl', () {
    test('null/빈 문자열/공백은 기본값', () {
      for (final v in [null, '', '   ']) {
        expect(ApiConstants.resolveProxyUrl(v), ApiConstants.defaultProxyUrl);
      }
    });
    test('값이 있으면 그 값', () {
      expect(ApiConstants.resolveProxyUrl('https://a.b'), 'https://a.b');
    });
  });

  group('로그인 오류', () {
    test('사용자 취소(CANCELED)는 오류로 보지 않는다', () {
      expect(isLoginCancelled(PlatformException(code: 'CANCELED')), isTrue);
      expect(isLoginCancelled(PlatformException(code: 'OTHER')), isFalse);
      expect(isLoginCancelled(Exception('x')), isFalse);
    });
    test('그 밖의 오류는 원문 대신 친화적 문장', () {
      final msg = loginErrorMessage(Exception('Token exchange failed'));
      expect(msg, isNot(contains('Exception')));
      expect(msg, contains('로그인'));
      final dio = DioException.connectionTimeout(
          timeout: const Duration(seconds: 30),
          requestOptions: RequestOptions());
      expect(loginErrorMessage(dio), '인터넷 연결을 확인해 주세요');
    });
  });

  group('buildStyleProfileUpdate', () {
    test('프로필 필드만 담고 feedback 등 다른 자식은 건드리지 않는다', () {
      final m = buildStyleProfileUpdate(
        styleProfile: {'primaryStyle': 'a'},
        summary: 's',
        recommendations: ['r'],
        now: DateTime(2026, 1, 1),
      );
      expect(m.keys.toSet(), {
        'styleProfile/primaryStyle',
        'analyzedAt',
        'summary',
        'recommendations',
      });
      expect(m['summary'], 's');
    });
    test('styleProfile을 통째로 덮지 않고 필드 경로로 쓴다', () {
      final m = buildStyleProfileUpdate(
        styleProfile: {'primaryStyle': 'a', 'moodKeywords': ['x']},
      );
      expect(m.containsKey('styleProfile'), isFalse);
      expect(m['styleProfile/moodKeywords'], ['x']);
    });
    test('수동 편집(요약 없음)이면 옛 요약을 null로 지운다', () {
      final m = buildStyleProfileUpdate(styleProfile: {});
      expect(m.containsKey('summary'), isTrue);
      expect(m['summary'], isNull);
      expect(m['recommendations'], isNull);
    });
  });

  group('StyleAnalysisNotifier.resetIfCompletedRun', () {
    test('완료된 같은 실행이면 초기화, 새 실행이 시작됐으면 유지', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(styleAnalysisPipelineProvider.notifier);

      n.state = const StyleAnalysisState(status: StyleAnalysisStatus.completed);
      n.resetIfCompletedRun(n.runId + 1); // 다른 실행 번호
      expect(container.read(styleAnalysisPipelineProvider).status,
          StyleAnalysisStatus.completed);

      n.resetIfCompletedRun(n.runId);
      expect(container.read(styleAnalysisPipelineProvider).status,
          StyleAnalysisStatus.idle);

      // 진행 중인 상태는 같은 번호여도 지우지 않는다.
      n.state =
          const StyleAnalysisState(status: StyleAnalysisStatus.fetchingMedia);
      n.resetIfCompletedRun(n.runId);
      expect(container.read(styleAnalysisPipelineProvider).status,
          StyleAnalysisStatus.fetchingMedia);
    });
  });
}
