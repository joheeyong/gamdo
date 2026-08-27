import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/database.dart';
import '../../../core/services/image_service.dart';
import '../domain/photo_analysis.dart';
import 'claude_datasource.dart';

part 'analysis_repository.g.dart';

@riverpod
AnalysisRepository analysisRepository(Ref ref) {
  return AnalysisRepository(
    datasource: GamdoAgentDatasource(ref.read(dioProvider)),
    imageService: ref.read(imageServiceProvider),
    database: ref.read(appDatabaseProvider),
  );
}

class AnalysisRepository {
  final GamdoAgentDatasource _datasource;
  final ImageService _imageService;
  final AppDatabase _database;

  AnalysisRepository({
    required GamdoAgentDatasource datasource,
    required ImageService imageService,
    required AppDatabase database,
  })  : _datasource = datasource,
        _imageService = imageService,
        _database = database;

  /// 사용자 스타일 분석 (게시글/피드/스토리 기반)
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts = const [],
    List<Map<String, dynamic>> feeds = const [],
    List<Map<String, dynamic>> stories = const [],
  }) async {
    return _datasource.analyzeUser(
      posts: posts,
      feeds: feeds,
      stories: stories,
    );
  }

  /// 사진 변형 가이드 (스타일 프로필 + 사진)
  Future<({int id, String analysisJson, String imagePath})> transformPhoto({
    required File imageFile,
    required Map<String, dynamic> styleProfile,
  }) async {
    // 1. 이미지 처리
    final processed = await _imageService.processImage(imageFile);

    // 2. 영구 저장소에 이미지 저장
    final appDir = await getApplicationDocumentsDirectory();
    final savedImagePath = p.join(
      appDir.path,
      'photos',
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await Directory(p.dirname(savedImagePath)).create(recursive: true);
    await processed.file.copy(savedImagePath);

    // 3. 에이전트 서버에 분석 요청
    final analysisMap = await _datasource.transformPhoto(
      styleProfile: styleProfile,
      imageBase64: processed.base64,
    );

    final analysisJson = jsonEncode(analysisMap);

    // 4. DB에 저장
    final styleCategory =
        (analysisMap['transformGuide']?['targetStyle'] as String?) ?? '분석완료';
    final colorTemp =
        (analysisMap['currentAnalysis']?['colorTemperature'] as String?) ?? 'neutral';
    final currentScore =
        (analysisMap['overallScore']?['current'] as num?)?.toInt() ?? 50;

    final id = await _database.insertAnalysis(
      AnalysisRecordsCompanion.insert(
        imagePath: savedImagePath,
        analysisJson: analysisJson,
        overallScore: currentScore,
        styleCategory: styleCategory,
        colorTemperature: colorTemp,
      ),
    );

    return (id: id, analysisJson: analysisJson, imagePath: savedImagePath);
  }
}
