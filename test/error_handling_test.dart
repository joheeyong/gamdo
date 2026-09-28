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

    test('Dio 타임아웃 메시지(receiveTimeout)를 네트워크 문제로 본다', () {
      final e = DioException.receiveTimeout(
        timeout: const Duration(seconds: 120),
        requestOptions: RequestOptions(),
      );
      // 예전 방식: 메시지만 넘기는 생성
      expect(ApiException(message: e.message!).userMessage, network);
      // 새 방식: 종류로 판단
      expect(ApiException.fromDio(e).userMessage, network);
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
    test('재분석 결과에 targetParams가 없으면 학습값 경로를 건드리지 않는다', () {
      final m = buildStyleProfileUpdate(
        styleProfile: {'primaryStyle': 'a', 'moodKeywords': ['x']},
      );
      expect(m.containsKey('styleProfile'), isFalse);
      expect(m.containsKey('styleProfile/targetParams'), isFalse);
      expect(m['styleProfile/moodKeywords'], ['x']);
    });
    test('수동 편집이 보존한 targetParams는 그 값으로 쓴다', () {
      final m = buildStyleProfileUpdate(styleProfile: {
        'targetParams': {'warmth': 0.2},
      });
      expect(m['styleProfile/targetParams'], {'warmth': 0.2});
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
