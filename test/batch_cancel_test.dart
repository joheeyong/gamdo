import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/features/analysis/di/analysis_providers.dart';
import 'package:gamdo/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:gamdo/features/analysis/presentation/providers/batch_transform_provider.dart';

typedef _Result = ({
  String analysisJson,
  String imagePath,
  Map<String, dynamic> fullResult,
});

/// 호출마다 Completer를 남겨 테스트가 응답 시점을 정하는 가짜 저장소.
class _FakeRepo implements AnalysisRepository {
  final calls = <({File file, CancelToken? token, Completer<_Result> c})>[];

  @override
  Future<_Result> analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
    bool reshapeEnabled = false,
    CancelToken? cancelToken,
  }) {
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
}
