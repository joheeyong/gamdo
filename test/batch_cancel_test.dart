import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/providers/style_profile_provider.dart';
import 'package:gamdo/features/analysis/di/analysis_providers.dart';
import 'package:gamdo/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:gamdo/features/analysis/presentation/providers/batch_transform_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Result = ({
  String analysisJson,
  String imagePath,
  Map<String, dynamic> fullResult,
});

/// 호출마다 Completer를 남겨 테스트가 응답 시점을 정하는 가짜 저장소.
class _FakeRepo implements AnalysisRepository {
  final calls = <({File file, CancelToken? token, Completer<_Result> c})>[];
  final skinRetouchFlags = <bool>[];
  final reshapeFlags = <bool>[];
  final styleProfiles = <Map<String, dynamic>?>[];

  @override
  Future<_Result> analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
    bool reshapeEnabled = false,
    bool skinRetouchEnabled = true,
    CancelToken? cancelToken,
  }) {
    skinRetouchFlags.add(skinRetouchEnabled);
    reshapeFlags.add(reshapeEnabled);
    styleProfiles.add(styleProfile);
    final c = Completer<_Result>();
    calls.add((file: imageFile, token: cancelToken, c: c));
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

_Result _ok() => (
      analysisJson: '{}',
      imagePath: '/x.jpg',
      fullResult: {'image_base64': 'AAAA', 'analysis': <String, dynamic>{}},
    );

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _FakeRepo();
    container = ProviderContainer(overrides: [
      analysisRepositoryDIProvider.overrideWithValue(repo),
    ]);
  });
  tearDown(() => container.dispose());

  BatchTransformNotifier notifier() =>
      container.read(batchTransformProvider.notifier);

  test('reset()하면 진행 중 요청이 취소되고 이전 루프가 state를 쓰지 않는다', () async {
    final files = [File('a.jpg'), File('b.jpg')];
    final run = notifier().startBatch(files);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, hasLength(1));

    notifier().reset();
    expect(repo.calls.first.token!.isCancelled, isTrue);

    // 취소 뒤 늦게 응답이 와도 무시되고, 다음 사진 요청도 나가지 않는다.
    repo.calls.first.c.complete(_ok());
    await run;

    final state = container.read(batchTransformProvider);
    expect(state.status, BatchStatus.idle);
    expect(state.results, isEmpty);
    expect(repo.calls, hasLength(1));
  });

  test('새 startBatch는 이전 루프를 멈추고 새 루프만 state를 쓴다', () async {
    final first = notifier().startBatch([File('a.jpg'), File('b.jpg')]);
    await Future<void>.delayed(Duration.zero);
    final second = notifier().startBatch([File('c.jpg')]);
    await Future<void>.delayed(Duration.zero);

    expect(repo.calls, hasLength(2));
    expect(repo.calls[0].token!.isCancelled, isTrue);

    repo.calls[0].c.completeError(DioException.requestCancelled(
      requestOptions: RequestOptions(),
      reason: 'cancel',
    ));
    repo.calls[1].c.complete(_ok());
    await Future.wait([first, second]);

    final state = container.read(batchTransformProvider);
    expect(state.status, BatchStatus.reviewing);
    expect(state.imageFiles.single.path, 'c.jpg');
    expect(state.results, hasLength(1));
    expect(state.results.single.isSuccess, isTrue);
    // 이전 배치의 두 번째 사진(b.jpg)은 요청되지 않았다.
    expect(repo.calls.map((c) => c.file.path), ['a.jpg', 'c.jpg']);
  });

  test('저장이 끝난(done) 뒤 saveAll을 다시 호출해도 저장하지 않는다', () async {
    // reviewing이 아닌 상태(idle)에서는 아무것도 저장하지 않는다.
    expect(await notifier().saveAll(), 0);
    expect(container.read(batchTransformProvider).status, BatchStatus.idle);
  });

  test('배치 분석도 설정의 피부 보정 값을 보낸다 (기본 켜짐 / 끄면 false)', () async {
    var run = notifier().startBatch([File('a.jpg')]);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, hasLength(1));
    repo.calls.last.c.complete(_ok());
    await run;
    expect(repo.skinRetouchFlags.last, isTrue);

    container.dispose();
    SharedPreferences.setMockInitialValues({'skin_retouch_enabled': false});
    container = ProviderContainer(overrides: [
      analysisRepositoryDIProvider.overrideWithValue(repo),
    ]);
    run = notifier().startBatch([File('b.jpg')]);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, hasLength(2));
    repo.calls.last.c.complete(_ok());
    await run;
    expect(repo.skinRetouchFlags.last, isFalse);
  });

  test('배치가 설정 화면을 연 적 없어도 저장된 얼굴/체형 보정 설정을 보낸다', () async {
    // 예전에는 autoDispose provider를 .value ?? false로 읽어(또는 아예 안 넘겨)
    // 켜 둔 사용자도 항상 꺼짐으로 전송됐다.
    SharedPreferences.setMockInitialValues({'reshape_enabled': true});
    final repo = _FakeRepo();
    final c = ProviderContainer(overrides: [
      analysisRepositoryDIProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    final run = c.read(batchTransformProvider.notifier).startBatch([File('a.jpg')]);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, hasLength(1));
    repo.calls.last.c.complete(_ok());
    await run;
    expect(repo.reshapeFlags.single, isTrue);
  });

  test('배치도 설정의 보정 스타일로 trendCategory를 바꿔 보낸다 (프로필은 그대로)',
      () async {
    SharedPreferences.setMockInitialValues({'edit_style': 'soft_pastel'});
    final repo = _FakeRepo();
    final c = ProviderContainer(overrides: [
      analysisRepositoryDIProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    c.read(userStyleProfileProvider.notifier).state = {
      'trendCategory': 'clean_minimal',
    };
    final run = c.read(batchTransformProvider.notifier).startBatch([File('a.jpg')]);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, hasLength(1));
    repo.calls.last.c.complete(_ok());
    await run;
    expect(repo.styleProfiles.single,
        {'trendCategory': 'soft_pastel', 'styleSource': 'manual'});
    expect(c.read(userStyleProfileProvider), {'trendCategory': 'clean_minimal'});
  });
}
