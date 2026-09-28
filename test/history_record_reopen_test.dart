import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/services/database.dart';
import 'package:gamdo/core/services/image_service.dart';
import 'package:gamdo/features/analysis/data/claude_datasource.dart';
import 'package:gamdo/features/analysis/data/repositories/analysis_repository_impl.dart';
import 'package:gamdo/features/analysis/data/repositories/transform_repository_impl.dart';
import 'package:gamdo/features/analysis/di/analysis_providers.dart';
import 'package:gamdo/features/analysis/domain/entities/stored_transform.dart';
import 'package:gamdo/features/analysis/presentation/providers/transform_provider.dart';
import 'package:gamdo/features/settings/presentation/providers/settings_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// 압축·썸네일 축소 플러그인 없이 동작하는 가짜 이미지 서비스.
class _FakeImageService extends ImageService {
  @override
  Future<({File file, String base64})> processImage(File originalFile) async =>
      (file: originalFile, base64: 'FULL');

  @override
  Future<String> processPreviewImage(File originalFile) async => 'PREVIEW';

  @override
  Future<File> saveThumbnail(Uint8List bytes, String targetPath) async {
    final file = File(targetPath);
    await file.parent.create(recursive: true);
    return file.writeAsBytes(bytes, flush: true);
  }
}

class _ReshapeOff extends ReshapeEnabledSetting {
  @override
  FutureOr<bool> build() => false;
}

/// 서버 대신 응답하고 요청을 기록하는 Dio.
class _CapturingServer {
  final requests = <RequestOptions>[];
  int analyzeCount = 0;
  late final Dio dio;

  _CapturingServer() {
    dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      requests.add(o);
      if (o.path.endsWith('/api/analyze-and-transform')) {
        analyzeCount++;
        h.resolve(Response(
          requestOptions: o,
          statusCode: 200,
          data: _analyzeResponse(analyzeCount),
        ));
      } else if (o.path.endsWith('/api/apply-transform')) {
        h.resolve(Response(
          requestOptions: o,
          statusCode: 200,
          data: {
            'success': true,
            'image_base64': base64Encode([7, 7, 7]),
          },
        ));
      } else {
        h.reject(DioException(requestOptions: o, error: 'unexpected ${o.path}'));
      }
    }));
  }

  List<RequestOptions> get applyRequests => [
        for (final r in requests)
          if (r.path.endsWith('/api/apply-transform')) r,
      ];
}

Map<String, dynamic> _analyzeResponse(int n) => {
      'success': true,
      'analysis': {
        'toneReport': {'styleCategory': '필름$n'},
        'colorAnalysis': {'colorTemperature': 'warm'},
        'feedCompatibility': 80,
        'autoEdits': {'straighten': 1.5, 'allow_vertical_crop': false},
        'regionParams': {
          'sky': {'saturation': 0.2},
        },
      },
      'image_base64': base64Encode([n, n, n]),
      'params': {
        'brightness': 0.2,
        'contrast': -0.1,
        'auto_wb': 0.5,
        'denoise': 0.3,
        'background_blur': 0.4,
        'tone_curve_preset': 'film',
        'tone_curve_strength': 0.5,
        'tone_curve_points': [
          [0.0, 0.1],
          [1.0, 0.9],
        ],
        'hsl_adjust': {
          'red': {'hue': 0.1, 'saturation': 0.2, 'lightness': 0.0},
        },
        'face_slim': 0.3,
        'waist_slim': 0.2,
      },
      'params_comment': '따뜻하게 $n',
    };

/// drift가 만든 v2 테이블 정의 (transformJson 이전).
const _v2Ddl = 'CREATE TABLE "analysis_records" ('
    '"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
    '"image_path" TEXT NOT NULL, '
    '"thumbnail_path" TEXT NULL, '
    '"analysis_json" TEXT NOT NULL, '
    '"style_category" TEXT NOT NULL, '
    '"color_temperature" TEXT NOT NULL, '
    '"created_at" INTEGER NOT NULL '
    "DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DB 마이그레이션', () {
    test('v2 → v3: 기존 행이 살아 있고 transformJson은 null, 새 컬럼에 쓸 수 있다',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        raw.execute(_v2Ddl);
        raw.execute(
          'INSERT INTO analysis_records (image_path, thumbnail_path, '
          'analysis_json, style_category, color_temperature, created_at) '
          "VALUES ('photos/a.jpg', 'photos/after_a.jpg', '{\"x\":1}', "
          "'필름', 'warm', 1700000000)",
        );
        raw.execute('PRAGMA user_version = 2');
      }));
      addTearDown(db.close);

      final rows = await db.getAllAnalyses();
      expect(rows, hasLength(1));
      expect(rows.single.imagePath, 'photos/a.jpg');
      expect(rows.single.thumbnailPath, 'photos/after_a.jpg');
      expect(rows.single.analysisJson, '{"x":1}');
      expect(rows.single.transformJson, isNull);

      await db.updateTransformJson(rows.single.id, '{"version":1}');
      expect((await db.getAnalysisById(rows.single.id))!.transformJson,
          '{"version":1}');

      final id = await db.insertAnalysis(AnalysisRecordsCompanion.insert(
        imagePath: 'photos/b.jpg',
        analysisJson: '{}',
        styleCategory: 's',
        colorTemperature: 'c',
        transformJson: const Value('{"version":1}'),
      ));
      expect((await db.getAnalysisById(id))!.transformJson, '{"version":1}');
    });

    test('v1 → v3: overallScore를 떼고 새 컬럼을 추가한다', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        raw.execute('CREATE TABLE "analysis_records" ('
            '"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
            '"image_path" TEXT NOT NULL, '
            '"thumbnail_path" TEXT NULL, '
            '"analysis_json" TEXT NOT NULL, '
            '"overall_score" INTEGER NOT NULL, '
            '"style_category" TEXT NOT NULL, '
            '"color_temperature" TEXT NOT NULL, '
            '"created_at" INTEGER NOT NULL)');
        raw.execute(
          'INSERT INTO analysis_records (image_path, analysis_json, '
          'overall_score, style_category, color_temperature, created_at) '
          "VALUES ('photos/a.jpg', '{}', 80, '필름', 'warm', 1700000000)",
        );
        raw.execute('PRAGMA user_version = 1');
      }));
      addTearDown(db.close);

      final rows = await db.getAllAnalyses();
      expect(rows.single.imagePath, 'photos/a.jpg');
      expect(rows.single.transformJson, isNull);
      // overallScore 없이 INSERT가 된다
      await db.insertAnalysis(AnalysisRecordsCompanion.insert(
        imagePath: 'photos/b.jpg',
        analysisJson: '{}',
        styleCategory: 's',
        colorTemperature: 'c',
      ));
      expect(await db.getAllAnalyses(), hasLength(2));
    });
  });

  group('기록 저장소 · 변형 복원', () {
    late Directory docs;
    late File source;
    late AppDatabase db;
    late _CapturingServer server;
    late AnalysisRepositoryImpl repo;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'proxy_url': 'http://test'});
      docs = await Directory.systemTemp.createTemp('gamdo_docs');
      source = File(p.join(docs.parent.path,
          'src_${DateTime.now().microsecondsSinceEpoch}.jpg'))
        ..writeAsBytesSync([1, 2, 3, 4]);
      db = AppDatabase.forTesting(NativeDatabase.memory());
      server = _CapturingServer();
      final datasource = GamdoAgentDatasource(server.dio);
      final imageService = _FakeImageService();
      repo = AnalysisRepositoryImpl(
        datasource: datasource,
        imageService: imageService,
        database: db,
        documentsDir: () async => docs.path,
      );
      container = ProviderContainer(overrides: [
        analysisRepositoryDIProvider.overrideWithValue(repo),
        transformRepositoryProvider.overrideWithValue(TransformRepositoryImpl(
          datasource: datasource,
          imageService: imageService,
        )),
        imageServiceProvider.overrideWithValue(imageService),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      if (docs.existsSync()) docs.deleteSync(recursive: true);
      if (source.existsSync()) source.deleteSync();
    });

    List<String> photoFiles({required bool thumbs}) => Directory(
          p.join(docs.path, 'photos'),
        )
            .listSync()
            .map((e) => p.basename(e.path))
            .where((n) => n.startsWith('after_') == thumbs)
            .toList();

    TransformNotifier notifier() => container.read(transformProvider.notifier);
    TransformState state() => container.read(transformProvider);

    test('새 분석은 기록을 넣고, recordId를 주면 그 기록을 갱신한다', () async {
      final first = await repo.analyzeAndTransformRecord(imageFile: source);
      var rows = await db.getAllAnalyses();
      expect(rows, hasLength(1));
      expect(rows.single.id, first.recordId);
      expect(rows.single.styleCategory, '필름1');
      final stored = StoredTransform.tryDecode(rows.single.transformJson);
      expect(stored, isNotNull);
      expect(stored!.paramsComment, '따뜻하게 1');
      expect(stored.autoEdits, {'straighten': 1.5, 'allow_vertical_crop': false});
      expect(stored.toneCurvePoints, hasLength(2));
      final oldThumb = rows.single.thumbnailPath!;
      expect(p.isRelative(oldThumb), isTrue);
      expect(photoFiles(thumbs: false), hasLength(1));

      // 밀리초 단위 파일 이름이 겹치지 않게
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await repo.analyzeAndTransformRecord(
        imageFile: File(first.imagePath),
        recordId: first.recordId,
      );
      rows = await db.getAllAnalyses();
      expect(rows, hasLength(1), reason: '다시 분석해도 기록이 늘지 않는다');
      expect(second.recordId, first.recordId);
      expect(second.imagePath, first.imagePath);
      expect(rows.single.styleCategory, '필름2');
      expect(StoredTransform.tryDecode(rows.single.transformJson)!.paramsComment,
          '따뜻하게 2');
      expect(rows.single.thumbnailPath, isNot(oldThumb));
      // 원본은 다시 복사하지 않고, 이전 썸네일은 지운다
      expect(photoFiles(thumbs: false), hasLength(1));
      expect(photoFiles(thumbs: true), [p.basename(rows.single.thumbnailPath!)]);
      expect(File(p.join(docs.path, oldThumb)).existsSync(), isFalse);
    });

    test('배치가 쓰는 analyzeAndTransform은 매번 새 기록을 넣고 transformJson도 남긴다',
        () async {
      await repo.analyzeAndTransform(imageFile: source);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.analyzeAndTransform(imageFile: source);
      final rows = await db.getAllAnalyses();
      expect(rows, hasLength(2));
      expect(rows.every((r) => StoredTransform.tryDecode(r.transformJson) != null),
          isTrue);
    });

    test('transformJson이 있는 기록을 열면 AI 없이 저장·공유와 같은 요청으로 복원한다',
        () async {
      final seeded = await repo.analyzeAndTransformRecord(imageFile: source);
      server.requests.clear();
      server.analyzeCount = 0;

      final opened =
          await notifier().openRecord(seeded.recordId, File(seeded.imagePath));

      expect(server.analyzeCount, 0, reason: 'AI 엔드포인트를 부르지 않는다');
      expect(server.requests.map((r) => r.path.split('/').last),
          ['apply-transform']);
      expect(await db.getAllAnalyses(), hasLength(1));
      expect(opened, isNotNull);
      expect(opened!.recordId, seeded.recordId);
      expect(jsonDecode(opened.analysisJson)['feedCompatibility'], 80);

      expect(state().status, TransformStatus.ready);
      expect(state().recordId, seeded.recordId);
      expect(state().transformedImageBytes, [7, 7, 7]);
      expect(state().paramsComment, '따뜻하게 1');
      expect(state().belongsTo(seeded.imagePath), isTrue);
      expect(state().belongsTo('/other.jpg', recordId: seeded.recordId), isTrue);
      expect(state().belongsTo(seeded.imagePath, recordId: seeded.recordId + 1),
          isFalse);

      final restoreReq = server.applyRequests.single.data as Map;
      expect(restoreReq['preview'], false);
      expect(restoreReq['image_base64'], 'FULL');
      expect(restoreReq['auto_edits'],
          {'straighten': 1.5, 'allow_vertical_crop': false});
      expect(restoreReq['region_params'], {
        'sky': {'saturation': 0.2},
      });
      expect(restoreReq['tone_curve_points'], [
        [0.0, 0.1],
        [1.0, 0.9],
      ]);
      expect(restoreReq['auto_wb'], 0.5);
      expect(restoreReq['denoise'], 0.3);
      expect(restoreReq['background_blur'], 0.4);
      expect(restoreReq['brightness'], 0.2);
      expect(restoreReq['tone_curve_preset'], 'film');
      expect(restoreReq['face_slim'], 0.3);

      // 저장·공유 경로와 요청이 한 글자도 다르지 않아야 한다
      await notifier().renderForExport(File(seeded.imagePath));
      final exportReq = server.applyRequests.last.data as Map;
      expect(exportReq, equals(restoreReq));
    });

    test('설정에서 체형 보정이 꺼져 있으면 복원 시 체형 값을 0으로 보낸다', () async {
      container.dispose();
      final datasource = GamdoAgentDatasource(server.dio);
      container = ProviderContainer(overrides: [
        analysisRepositoryDIProvider.overrideWithValue(repo),
        transformRepositoryProvider.overrideWithValue(TransformRepositoryImpl(
          datasource: datasource,
          imageService: _FakeImageService(),
        )),
        imageServiceProvider.overrideWithValue(_FakeImageService()),
        reshapeEnabledSettingProvider.overrideWith(_ReshapeOff.new),
      ]);
      container.listen(reshapeEnabledSettingProvider, (_, _) {});
      await container.read(reshapeEnabledSettingProvider.future);

      final seeded = await repo.analyzeAndTransformRecord(imageFile: source);
      await notifier().openRecord(seeded.recordId, File(seeded.imagePath));

      final req = server.applyRequests.single.data as Map;
      expect(req['face_slim'], 0.0);
      expect(req['waist_slim'], 0.0);
      expect(req['brightness'], 0.2);
    });

    test('transformJson이 없는 옛 기록은 한 번 분석하되 그 기록을 갱신한다', () async {
      final photos = Directory(p.join(docs.path, 'photos'))
        ..createSync(recursive: true);
      File(p.join(photos.path, 'old.jpg')).writeAsBytesSync([1, 2, 3]);
      File(p.join(photos.path, 'after_old.jpg')).writeAsBytesSync([4, 5]);
      final id = await db.insertAnalysis(AnalysisRecordsCompanion.insert(
        imagePath: 'photos/old.jpg',
        thumbnailPath: const Value('photos/after_old.jpg'),
        analysisJson: '{}',
        styleCategory: '옛',
        colorTemperature: 'neutral',
      ));

      final opened = await notifier()
          .openRecord(id, File(p.join(docs.path, 'photos', 'old.jpg')));

      expect(server.analyzeCount, 1);
      expect(opened!.recordId, id);
      final rows = await db.getAllAnalyses();
      expect(rows, hasLength(1));
      expect(rows.single.imagePath, 'photos/old.jpg');
      expect(rows.single.styleCategory, '필름1');
      expect(StoredTransform.tryDecode(rows.single.transformJson), isNotNull);
      expect(rows.single.thumbnailPath, isNot('photos/after_old.jpg'));
      expect(File(p.join(photos.path, 'after_old.jpg')).existsSync(), isFalse);
      expect(photoFiles(thumbs: false), ['old.jpg']);
      expect(state().recordId, id);

      // 이제는 AI 없이 다시 열린다
      server.analyzeCount = 0;
      await notifier()
          .openRecord(id, File(p.join(docs.path, 'photos', 'old.jpg')));
      expect(server.analyzeCount, 0);
    });

    test('기록에 묶인 화면의 다시 분석은 새 기록을 만들지 않는다', () async {
      final seeded = await repo.analyzeAndTransformRecord(imageFile: source);
      await notifier().openRecord(seeded.recordId, File(seeded.imagePath));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final again = await notifier().analyzeAndTransform(
        File(seeded.imagePath),
        recordId: state().recordId,
      );

      expect(again!.recordId, seeded.recordId);
      expect(await db.getAllAnalyses(), hasLength(1));
      expect(server.analyzeCount, 2);
      expect(photoFiles(thumbs: false), hasLength(1));
      expect(photoFiles(thumbs: true), hasLength(1));
    });
  });

  group('StoredTransform', () {
    test('모르는 버전·깨진 JSON은 null (옛 기록처럼 다시 분석)', () {
      expect(StoredTransform.tryDecode(null), isNull);
      expect(StoredTransform.tryDecode('not json'), isNull);
      expect(StoredTransform.tryDecode('{"version":99,"params":{}}'), isNull);
      expect(StoredTransform.tryDecode('{"version":1}'), isNull);
    });

    test('서버 응답을 인코딩했다가 그대로 되살린다', () {
      final t = StoredTransform.fromServerResult(_analyzeResponse(1));
      final back = StoredTransform.tryDecode(t.encode())!;
      expect(back.params, _analyzeResponse(1)['params']);
      expect(back.regionParams, {
        'sky': {'saturation': 0.2},
      });
      expect(back.transformParams.autoWb, 0.5);
      expect(back.transformParams.hslAdjust?['red']?['saturation'], 0.2);
    });
  });
}
