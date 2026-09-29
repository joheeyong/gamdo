import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/network/api_exception.dart';
import 'package:gamdo/features/analysis/data/claude_datasource.dart';
import 'package:gamdo/features/analysis/domain/entities/analysis_job_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 서버 대신 응답하는 가짜. 경로별 응답을 테스트가 정한다.
class _FakeServer {
  final requests = <RequestOptions>[];
  late final Dio dio;

  /// POST /api/jobs/analyze-and-transform 응답 (호출 순서대로 소비, 마지막은 반복).
  final starts = <_Reply Function(RequestOptions)>[];

  /// GET /api/jobs/{id} 응답 (호출 순서대로 소비, 마지막은 반복).
  final polls = <_Reply Function(RequestOptions)>[];

  /// POST /api/analyze-and-transform (동기 폴백) 응답.
  _Reply Function(RequestOptions)? sync;

  int _startIdx = 0;
  int _pollIdx = 0;

  _FakeServer() {
    dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      requests.add(o);
      final path = o.uri.path;
      _Reply reply;
      if (o.method == 'POST' && path.endsWith('/api/jobs/analyze-and-transform')) {
        reply = starts[_startIdx < starts.length ? _startIdx++ : starts.length - 1](o);
      } else if (o.method == 'GET' && path.contains('/api/jobs/')) {
        reply = polls[_pollIdx < polls.length ? _pollIdx++ : polls.length - 1](o);
      } else if (o.method == 'POST' && path.endsWith('/api/analyze-and-transform')) {
        reply = sync!(o);
      } else {
        reply = _Reply.status(500, {'detail': 'unexpected $path'});
      }
      reply.send(o, h);
    }));
  }

  List<RequestOptions> get startRequests => [
        for (final r in requests)
          if (r.method == 'POST' && r.uri.path.endsWith('/api/jobs/analyze-and-transform')) r,
      ];

  List<RequestOptions> get pollRequests => [
        for (final r in requests)
          if (r.method == 'GET' && r.uri.path.contains('/api/jobs/')) r,
      ];

  List<RequestOptions> get syncRequests => [
        for (final r in requests)
          if (r.uri.path.endsWith('/api/analyze-and-transform') &&
              !r.uri.path.contains('/jobs/'))
            r,
      ];
}

class _Reply {
  final int? statusCode;
  final Object? data;
  final DioExceptionType? networkError;

  const _Reply.status(this.statusCode, this.data) : networkError = null;
  const _Reply.network(DioExceptionType type)
      : statusCode = null,
        data = null,
        networkError = type;

  void send(RequestOptions o, RequestInterceptorHandler h) {
    if (networkError != null) {
      h.reject(DioException(requestOptions: o, type: networkError!, error: 'net'));
      return;
    }
    final response = Response(requestOptions: o, statusCode: statusCode, data: data);
    if (statusCode! >= 200 && statusCode! < 300) {
      h.resolve(response);
    } else {
      h.reject(DioException(
        requestOptions: o,
        response: response,
        type: DioExceptionType.badResponse,
      ));
    }
  }
}

Map<String, dynamic> _result([String tag = 'A']) => {
      'success': true,
      'analysis': {
        'toneReport': {'styleCategory': '필름'},
      },
      'image_base64': 'IMG_$tag',
      'params': {'brightness': 0.2},
      'params_comment': '따뜻하게',
      'error': null,
    };

_Reply Function(RequestOptions) _started(String id, [String status = 'queued']) =>
    (_) => _Reply.status(202, {'success': true, 'job_id': id, 'status': status});

_Reply Function(RequestOptions) _job(
  String status,
  String stage,
  double elapsed, {
  Map<String, dynamic>? result,
  String? error,
}) =>
    (o) => _Reply.status(200, {
          'success': true,
          'job_id': o.uri.pathSegments.last,
          'status': status,
          'stage': stage,
          'elapsed_sec': elapsed,
          // 서버는 해당 status가 아니어도 키를 빼지 않고 null로 보낸다
          'result': result,
          'error': error,
        });

_Reply Function(RequestOptions) _notFound() => (_) => const _Reply.status(
    404, {'success': false, 'error': 'not found', 'error_code': 'job_not_found'});

void main() {
  late _FakeServer server;
  late DateTime clock;
  late List<Duration> delays;
  late StreamController<void> resume;

  /// 기본 가짜 대기: 즉시 끝나고 시계를 그만큼 흘린다.
  Future<void> instantDelay(Duration d) {
    delays.add(d);
    clock = clock.add(d);
    return Future<void>.value();
  }

  GamdoAgentDatasource datasource({Future<void> Function(Duration)? delay}) =>
      GamdoAgentDatasource(
        server.dio,
        delay: delay ?? instantDelay,
        now: () => clock,
        resumeSignal: resume.stream,
      );

  Future<Map<String, dynamic>> analyze(
    GamdoAgentDatasource ds, {
    CancelToken? cancelToken,
    void Function(AnalysisJobProgress)? onProgress,
  }) =>
      ds.analyzeAndTransform(
        imageBase64: 'B64',
        styleProfile: const {'tone': 'warm'},
        userId: 'u1',
        reshapeEnabled: true,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = _FakeServer();
    clock = DateTime(2026, 9, 29, 12);
    delays = [];
    resume = StreamController<void>.broadcast();
  });

  tearDown(() => resume.close());

  test('시작 → queued → running → done이면 기존 동기 응답과 같은 result를 돌려준다', () async {
    server.starts.add(_started('job1'));
    server.polls
      ..add(_job('queued', 'queued', 0.5))
      ..add(_job('running', 'analyzing', 3.0))
      ..add(_job('running', 'rendering', 30.0))
      ..add(_job('done', 'done', 41.2, result: _result()));

    final result = await analyze(datasource());

    expect(result, _result());
    expect(server.startRequests.single.data, {
      'image_base64': 'B64',
      'style_profile': {'tone': 'warm'},
      'user_id': 'u1',
      'media_type': 'image/jpeg',
      'reshape_enabled': true,
    });
    expect(server.pollRequests, hasLength(4));
    expect(server.pollRequests.every((r) => r.uri.path.endsWith('/api/jobs/job1')),
        isTrue);
    expect(server.syncRequests, isEmpty);
    // 폴링 간격 1.5초, 요청 제한 20초
    expect(delays.first, GamdoAgentDatasource.pollInterval);
    expect(server.pollRequests.first.receiveTimeout, const Duration(seconds: 20));
    expect(server.startRequests.single.receiveTimeout, const Duration(seconds: 30));
  });

  test('진행 콜백으로 단계와 경과 시간을 알린다', () async {
    server.starts.add(_started('job1'));
    server.polls
      ..add(_job('running', 'analyzing', 3.0))
      ..add(_job('running', 'rendering', 30.5))
      ..add(_job('done', 'done', 41.0, result: _result()));

    final progress = <AnalysisJobProgress>[];
    await analyze(datasource(), onProgress: progress.add);

    expect(progress.map((p) => p.stage), [
      AnalysisJobStage.queued,
      AnalysisJobStage.analyzing,
      AnalysisJobStage.rendering,
      AnalysisJobStage.done,
    ]);
    expect(progress[1].elapsed, const Duration(seconds: 3));
    expect(progress[2].elapsed, const Duration(milliseconds: 30500));
    expect(progress.every((p) => p.resumable), isTrue);
  });

  test('폴링 중 네트워크 오류·타임아웃·5xx는 일시 오류로 보고 계속 조회한다', () async {
    server.starts.add(_started('job1'));
    server.polls
      ..add((_) => const _Reply.network(DioExceptionType.connectionError))
      ..add((_) => const _Reply.network(DioExceptionType.receiveTimeout))
      ..add((_) => const _Reply.status(502, 'Bad Gateway'))
      ..add((_) => const _Reply.network(DioExceptionType.unknown))
      ..add(_job('done', 'done', 40, result: _result()));

    final result = await analyze(datasource());

    expect(result['image_base64'], 'IMG_A');
    expect(server.pollRequests, hasLength(5));
    expect(server.startRequests, hasLength(1));
  });

  test('일시 오류가 10분 넘게 이어지면 마감 오류로 끝낸다', () async {
    server.starts.add(_started('job1'));
    server.polls.add((_) => const _Reply.network(DioExceptionType.connectionError));

    await expectLater(
      analyze(datasource()),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 504)),
    );
    // 20초까지는 1.5초, 그 뒤로는 3초 간격
    expect(delays, contains(GamdoAgentDatasource.slowPollInterval));
    expect(clock.difference(DateTime(2026, 9, 29, 12)),
        greaterThan(GamdoAgentDatasource.jobDeadline));
  });

  test('작업 API가 404/405면(구버전 서버) 동기 엔드포인트로 폴백하고 다음엔 바로 쓴다', () async {
    for (final code in [404, 405]) {
      server = _FakeServer();
      server.starts.add((_) => _Reply.status(code, {'detail': 'Not Found'}));
      server.sync = (_) => _Reply.status(200, _result('SYNC'));

      final ds = datasource();
      final progress = <AnalysisJobProgress>[];
      final result = await analyze(ds, onProgress: progress.add);

      expect(result, _result('SYNC'));
      expect(server.startRequests, hasLength(1));
      expect(server.syncRequests.single.data['reshape_enabled'], isTrue);
      expect(server.pollRequests, isEmpty);
      expect(progress.single.resumable, isFalse);

      // 같은 datasource의 다음 분석은 작업 API를 다시 두드리지 않는다
      await analyze(ds);
      expect(server.startRequests, hasLength(1), reason: 'code $code');
      expect(server.syncRequests, hasLength(2));
    }
  });

  test('폴링 중 job_not_found(서버 재시작)면 작업을 한 번 다시 시작한다', () async {
    server.starts
      ..add(_started('job1'))
      ..add(_started('job2', 'running'));
    server.polls
      ..add(_job('running', 'analyzing', 5))
      ..add(_notFound())
      ..add(_job('done', 'done', 2, result: _result('B')));

    final result = await analyze(datasource());

    expect(result['image_base64'], 'IMG_B');
    expect(server.startRequests, hasLength(2));
    expect(server.pollRequests.last.uri.path, endsWith('/api/jobs/job2'));
  });

  test('다시 시작한 작업도 사라지면 더 시작하지 않고 실패한다', () async {
    server.starts.add(_started('job1'));
    server.polls.add(_notFound());

    await expectLater(
      analyze(datasource()),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
    expect(server.startRequests, hasLength(2));
  });

  test('작업이 error면 서버 메시지로 ApiException을 던진다', () async {
    const msg = '사진 분석에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    server.starts.add(_started('job1'));
    server.polls
      ..add(_job('running', 'analyzing', 3))
      ..add(_job('error', 'error', 9, error: msg));

    await expectLater(
      analyze(datasource()),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', msg)),
    );
    expect(server.pollRequests, hasLength(2));
  });

  test('시작 시 503 busy면 재시도 없이 "요청이 많아요"로 실패한다', () async {
    server.starts.add((_) => const _Reply.status(503, {
          'success': false,
          'error': '지금 요청이 많아요',
          'error_code': 'busy',
        }));

    Object? error;
    try {
      await analyze(datasource());
    } catch (e) {
      error = e;
    }

    expect(error, isA<ApiException>());
    final e = error as ApiException;
    expect(e.statusCode, 503);
    expect(e.userMessage, '요청이 많아요. 잠시 후 다시 시도해 주세요');
    expect(server.startRequests, hasLength(1));
    expect(server.pollRequests, isEmpty);
    expect(server.syncRequests, isEmpty);
  });

  test('합치기로 이미 끝난 작업을 받으면 기다리지 않고 바로 조회한다', () async {
    server.starts.add(_started('job1', 'done'));
    server.polls.add(_job('done', 'done', 40, result: _result()));

    final result = await analyze(datasource());

    expect(result, _result());
    expect(delays, isEmpty);
  });

  test('취소하면 폴링을 멈추고 DioException(cancel)을 던진다', () async {
    server.starts.add(_started('job1'));
    server.polls.add(_job('running', 'analyzing', 3));
    final pending = <Completer<void>>[];
    final ds = datasource(delay: (d) {
      final c = Completer<void>();
      pending.add(c);
      return c.future;
    });

    final token = CancelToken();
    final future = analyze(ds, cancelToken: token);
    await pumpEventQueue();
    expect(pending, hasLength(1), reason: '첫 폴링을 기다리는 중');

    token.cancel('사용자 취소');

    await expectLater(
      future,
      throwsA(isA<DioException>()
          .having((e) => e.type, 'type', DioExceptionType.cancel)),
    );
    expect(server.pollRequests, isEmpty);
    // 대기가 끝나도 더는 폴링하지 않는다
    pending.single.complete();
    await pumpEventQueue();
    expect(server.pollRequests, isEmpty);
  });

  test('앱이 foreground로 돌아오면 간격을 기다리지 않고 바로 폴링한다', () async {
    server.starts.add(_started('job1'));
    server.polls
      ..add(_job('running', 'analyzing', 3))
      ..add(_job('done', 'done', 60, result: _result()));
    // 대기가 끝나지 않는다 — 복귀 신호만이 폴링을 깨운다
    final ds = datasource(delay: (_) => Completer<void>().future);

    Map<String, dynamic>? result;
    final future = analyze(ds).then((r) => result = r);
    await pumpEventQueue();
    expect(server.pollRequests, isEmpty);

    resume.add(null);
    await pumpEventQueue();
    expect(server.pollRequests, hasLength(1));
    expect(result, isNull);

    resume.add(null);
    await future;
    expect(server.pollRequests, hasLength(2));
    expect(result, _result());
  });
}
