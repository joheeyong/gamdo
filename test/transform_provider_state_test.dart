import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/providers/style_profile_provider.dart';
import 'package:gamdo/core/services/image_service.dart';
import 'package:gamdo/features/analysis/di/analysis_providers.dart';
import 'package:gamdo/features/analysis/domain/entities/analysis_job_progress.dart';
import 'package:gamdo/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:gamdo/features/analysis/domain/repositories/transform_repository.dart';
import 'package:gamdo/features/analysis/presentation/providers/transform_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Result = ({
  String analysisJson,
  String imagePath,
  Map<String, dynamic> fullResult
});

class _FakeImageService extends ImageService {
  @override
  Future<({File file, String base64})> processImage(File originalFile) async =>
      (file: originalFile, base64: 'FULL');

  @override
  Future<String> processPreviewImage(File originalFile) async => 'PREVIEW';
}

/// 호출마다 [next]가 돌려주는 Future를 결과로 쓴다.
class _FakeAnalysisRepository implements AnalysisRepository {
  Future<_Result> Function(File imageFile, CancelToken? token) next =
      (f, t) async => throw UnimplementedError();

  /// 마지막 analyzeAndTransformRecord 호출이 받은 피부 보정 설정.
  bool? lastSkinRetouchEnabled;

  /// 마지막 analyzeAndTransformRecord 호출이 받은 style_profile.
  Map<String, dynamic>? lastStyleProfile;

  /// 마지막 analyzeAndTransformRecord 호출이 받은 진행 콜백.
  void Function(AnalysisJobProgress progress)? lastOnProgress;

  @override
  Future<_Result> analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
    bool reshapeEnabled = false,
    bool skinRetouchEnabled = true,
    CancelToken? cancelToken,
  }) =>
      next(imageFile, cancelToken);

  @override
  Future<AnalyzeRecordResult> analyzeAndTransformRecord({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
    bool reshapeEnabled = false,
    bool skinRetouchEnabled = true,
    CancelToken? cancelToken,
    int? recordId,
    void Function(AnalysisJobProgress progress)? onProgress,
  }) async {
    lastOnProgress = onProgress;
    lastSkinRetouchEnabled = skinRetouchEnabled;
    lastStyleProfile = styleProfile;
    final r = await next(imageFile, cancelToken);
    return (
      recordId: recordId ?? 1,
      analysisJson: r.analysisJson,
      imagePath: r.imagePath,
      fullResult: r.fullResult,
    );
  }

  @override
  Future<SavedAnalysis?> loadRecord(int recordId) async => null;

  @override
  Future<void> updateStoredAutoEdits(
      int recordId, Map<String, dynamic>? autoEdits) async {}

  @override
  Future<List<String>> fetchReferenceImages(String userId) async => [];

  @override
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts = const [],
    List<Map<String, dynamic>> feeds = const [],
    List<Map<String, dynamic>> stories = const [],
    String userId = '',
  }) async =>
      {};
}

class _FakeTransformRepository implements TransformRepository {
  TransformParams? lastParams;
  Map<String, dynamic>? lastRegionParams;
  bool fail = false;

  @override
  Future<Map<String, dynamic>> applyManualTransform({
    File? imageFile,
    String? imageBase64,
    bool preview = false,
    required TransformParams params,
    Map<String, dynamic>? autoEdits,
    Map<String, dynamic>? regionParams,
    List<dynamic>? toneCurvePoints,
    CancelToken? cancelToken,
  }) async {
    lastParams = params;
    lastRegionParams = regionParams;
    if (fail) throw Exception('network');
    return {'success': true, 'image_base64': base64Encode([9, 9, 9])};
  }

  @override
  Future<TransformResult> autoTransform({
    required File imageFile,
    required Map<String, dynamic> analysis,
    Map<String, dynamic>? styleProfile,
  }) =>
      throw UnimplementedError();
}

_Result _result(String savedPath,
        {Map<String, dynamic>? params,
        Map<String, dynamic>? analysis,
        String? comment,
        List<int> bytes = const [1, 2, 3]}) =>
    (
      analysisJson: jsonEncode(analysis ?? {}),
      imagePath: savedPath,
      fullResult: {
        'success': true,
        'image_base64': base64Encode(bytes),
        'params': params ?? <String, dynamic>{},
        'params_comment': ?comment,
        'analysis': analysis ?? <String, dynamic>{},
      },
    );

void main() {
  late _FakeAnalysisRepository analysisRepo;
  late _FakeTransformRepository transformRepo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    analysisRepo = _FakeAnalysisRepository();
    transformRepo = _FakeTransformRepository();
    container = ProviderContainer(overrides: [
      analysisRepositoryDIProvider.overrideWithValue(analysisRepo),
      transformRepositoryProvider.overrideWithValue(transformRepo),
      imageServiceProvider.overrideWithValue(_FakeImageService()),
    ]);
  });

  tearDown(() => container.dispose());

  TransformNotifier notifier() => container.read(transformProvider.notifier);
  TransformState state() => container.read(transformProvider);

  test('새 사진을 분석하면 이전 사진의 영역 보정·톤 커브·설명이 남지 않는다', () async {
    analysisRepo.next = (f, t) async => _result(
          '/saved/a.jpg',
          params: {
            'brightness': 0.2,
            'tone_curve_points': [
              [0.0, 0.1],
              [1.0, 0.9],
            ],
          },
          analysis: {
            'regionParams': {'sky': <String, dynamic>{}},
            'autoEdits': {'straighten': 1.0},
          },
          comment: '이전 사진 설명',
        );
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));
    expect(state().regionParams, isNotNull);
    expect(state().toneCurvePoints, isNotNull);
    expect(state().paramsComment, '이전 사진 설명');

    analysisRepo.next = (f, t) async => _result('/saved/b.jpg');
    await notifier().analyzeAndTransform(File('/picked/b.jpg'));

    expect(state().status, TransformStatus.ready);
    expect(state().regionParams, isNull);
    expect(state().autoEdits, isNull);
    expect(state().toneCurvePoints, isNull);
    expect(state().paramsComment, isNull);
    expect(state().params.brightness, 0.0);
  });

  test('피부 보정이 꺼져 있으면 분석에 false를, 슬라이더 미리보기엔 피부 값 0을 보낸다',
      () async {
    SharedPreferences.setMockInitialValues({'skin_retouch_enabled': false});
    analysisRepo.next = (f, t) async => _result(
          '/saved/a.jpg',
          params: {'brightness': 0.2, 'skin_smoothing': 0.4},
          analysis: {
            'regionParams': {
              'face': {'skin_smoothing': 0.3, 'blemish_removal': 0.2},
            },
          },
        );
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));
    expect(analysisRepo.lastSkinRetouchEnabled, isFalse);

    await notifier().applyManual(
      File('/picked/a.jpg'),
      state().params.copyWith(blemishRemoval: 0.5, brightness: 0.3),
    );
    expect(transformRepo.lastParams!.skinSmoothing, 0.0);
    expect(transformRepo.lastParams!.blemishRemoval, 0.0);
    expect(transformRepo.lastParams!.brightness, 0.3);
    expect(transformRepo.lastRegionParams, {
      'face': {'skin_smoothing': 0.0, 'blemish_removal': 0.0},
    });
  });

  test('피부 보정이 켜져 있으면(기본) 분석에 true를 보내고 피부 값을 그대로 쓴다',
      () async {
    analysisRepo.next = (f, t) async =>
        _result('/saved/a.jpg', params: {'skin_smoothing': 0.4});
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));
    expect(analysisRepo.lastSkinRetouchEnabled, isTrue);

    await notifier().applyManual(File('/picked/a.jpg'), state().params);
    expect(transformRepo.lastParams!.skinSmoothing, 0.4);
  });

  test('보정 스타일을 직접 고르면 분석·기록 복원 폴백 모두 trendCategory를 바꿔 보낸다',
      () async {
    SharedPreferences.setMockInitialValues({'edit_style': 'flash_digicam'});
    final stored = <String, dynamic>{'trendCategory': 'warm_film', 'tone': 'warm'};
    container.read(userStyleProfileProvider.notifier).state = stored;
    analysisRepo.next = (f, t) async => _result('/saved/a.jpg');

    await notifier().analyzeAndTransform(File('/picked/a.jpg'));
    expect(analysisRepo.lastStyleProfile, {
      'trendCategory': 'flash_digicam',
      'tone': 'warm',
      'styleSource': 'manual',
    });
    expect(state().appliedStyleName, '플래시·디카');
    // 저장된 프로필은 그대로
    expect(container.read(userStyleProfileProvider),
        {'trendCategory': 'warm_film', 'tone': 'warm'});

    // 재현 정보 없는 기록 → 분석으로 폴백해도 같은 프로필
    analysisRepo.lastStyleProfile = null;
    await notifier().openRecord(7, File('/picked/a.jpg'));
    expect(analysisRepo.lastStyleProfile?['trendCategory'], 'flash_digicam');
    expect(analysisRepo.lastStyleProfile?['styleSource'], 'manual');
  });

  test('프로필이 없고 스타일을 골랐으면 trendCategory·styleSource만 보낸다', () async {
    SharedPreferences.setMockInitialValues({'edit_style': 'bw_grain'});
    analysisRepo.next = (f, t) async => _result('/saved/a.jpg');
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));
    expect(analysisRepo.lastStyleProfile,
        {'trendCategory': 'bw_grain', 'styleSource': 'manual'});
  });

  test('자동(기본)이면 프로필을 그대로(없으면 null) 보낸다', () async {
    analysisRepo.next = (f, t) async => _result('/saved/a.jpg');
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));
    expect(analysisRepo.lastStyleProfile, isNull);
    expect(state().appliedStyleName, isNull);

    final stored = <String, dynamic>{'trendCategory': 'warm_film'};
    container.read(userStyleProfileProvider.notifier).state = stored;
    await notifier().analyzeAndTransform(File('/picked/b.jpg'));
    expect(analysisRepo.lastStyleProfile, same(stored));
  });

  test('결과가 어떤 사진의 것인지 원본·저장 경로로 판별한다', () async {
    analysisRepo.next = (f, t) async => _result('/saved/a.jpg');
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));

    expect(state().belongsTo('/picked/a.jpg'), isTrue);
    expect(state().belongsTo('/saved/a.jpg'), isTrue);
    expect(state().belongsTo('/saved/other.jpg'), isFalse);
    expect(const TransformState().belongsTo('/saved/a.jpg'), isFalse);
  });

  test('분석을 취소하면 idle로 돌아가고, 늦게 온 응답이 상태를 덮지 않는다', () async {
    final completer = Completer<_Result>();
    CancelToken? seen;
    analysisRepo.next = (f, t) {
      seen = t;
      return completer.future;
    };

    final future = notifier().analyzeAndTransform(File('/picked/a.jpg'));
    await Future<void>.delayed(Duration.zero);
    expect(state().status, TransformStatus.loadingAutoTransform);

    notifier().cancelAutoTransform();
    expect(state().status, TransformStatus.idle);
    expect(seen?.isCancelled, isTrue);

    completer.complete(_result('/saved/a.jpg'));
    expect(await future, isNull);
    expect(state().status, TransformStatus.idle);
    expect(state().transformedImageBytes, isNull);
  });

  test('재시도에 밀린 이전 요청의 실패가 새 요청의 로딩 상태를 덮지 않는다', () async {
    final first = Completer<_Result>();
    final second = Completer<_Result>();
    var call = 0;
    analysisRepo.next = (f, t) => (++call == 1 ? first : second).future;

    final f1 = notifier().analyzeAndTransform(File('/picked/a.jpg'));
    await Future<void>.delayed(Duration.zero);
    final f2 = notifier().analyzeAndTransform(File('/picked/a.jpg'));
    await Future<void>.delayed(Duration.zero);

    first.completeError(Exception('old request failed'));
    expect(await f1, isNull);
    expect(state().status, TransformStatus.loadingAutoTransform);
    expect(state().errorMessage, isNull);

    second.complete(_result('/saved/a.jpg'));
    expect(await f2, isNotNull);
    expect(state().status, TransformStatus.ready);
  });

  test('저장용 재렌더링에 auto_wb/denoise/background_blur가 실린다', () async {
    analysisRepo.next = (f, t) async => _result('/saved/a.jpg', params: {
          'auto_wb': 0.6,
          'denoise': 0.4,
          'background_blur': 0.25,
        });
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));

    final bytes = await notifier().renderForExport(File('/picked/a.jpg'));
    expect(bytes, Uint8List.fromList([9, 9, 9]));
    expect(transformRepo.lastParams?.autoWb, 0.6);
    expect(transformRepo.lastParams?.denoise, 0.4);
    expect(transformRepo.lastParams?.backgroundBlur, 0.25);
  });

  test('재렌더링 실패 시 화면의 After가 최종 화질이면 그걸 쓴다', () async {
    analysisRepo.next = (f, t) async => _result('/saved/a.jpg', bytes: [7, 7]);
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));

    transformRepo.fail = true;
    final bytes = await notifier().renderForExport(File('/picked/a.jpg'));
    expect(bytes, Uint8List.fromList([7, 7]));
  });

  test('미리보기 바이트뿐이면 재렌더링 실패를 null로 알린다', () async {
    analysisRepo.next = (f, t) async => _result('/saved/a.jpg');
    await notifier().analyzeAndTransform(File('/picked/a.jpg'));
    // 슬라이더 미리보기로 바이트가 저해상도로 바뀐 상태
    await notifier()
        .applyManual(File('/picked/a.jpg'), state().params.copyWith(brightness: 0.3));

    transformRepo.fail = true;
    expect(await notifier().renderForExport(File('/picked/a.jpg')), isNull);
  });

  test('분석 진행 단계가 로딩 중 상태에 반영되고, 밀린 요청의 알림은 무시된다', () async {
    final first = Completer<_Result>();
    analysisRepo.next = (f, t) => first.future;
    final f1 = notifier().analyzeAndTransform(File('/picked/a.jpg'));
    await pumpEventQueue();
    final oldProgress = analysisRepo.lastOnProgress!;

    oldProgress(const AnalysisJobProgress(
      stage: AnalysisJobStage.analyzing,
      elapsed: Duration(seconds: 3),
    ));
    expect(state().status, TransformStatus.loadingAutoTransform);
    expect(state().analysisProgress?.stage, AnalysisJobStage.analyzing);
    expect(state().analysisProgress?.elapsed, const Duration(seconds: 3));

    // 새 요청이 시작되면 진행 상황도 비워지고, 이전 요청의 알림은 버린다
    final second = Completer<_Result>();
    analysisRepo.next = (f, t) => second.future;
    final f2 = notifier().analyzeAndTransform(File('/picked/b.jpg'));
    await pumpEventQueue();
    expect(state().analysisProgress, isNull);
    oldProgress(const AnalysisJobProgress(stage: AnalysisJobStage.rendering));
    expect(state().analysisProgress, isNull);

    analysisRepo.lastOnProgress!(
        const AnalysisJobProgress(stage: AnalysisJobStage.rendering));
    expect(state().analysisProgress?.stage, AnalysisJobStage.rendering);

    first.complete(_result('/saved/a.jpg'));
    second.complete(_result('/saved/b.jpg'));
    await Future.wait([f1, f2]);
    expect(state().status, TransformStatus.ready);
  });
}
