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
    String userId = '',
  }) async {
    return _datasource.analyzeUser(
      posts: posts,
      feeds: feeds,
      stories: stories,
      userId: userId,
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
        (analysisMap['toneReport']?['styleCategory'] as String?) ?? '분석완료';
    final colorTemp =
        (analysisMap['colorAnalysis']?['colorTemperature'] as String?) ?? 'neutral';
    final currentScore =
        (analysisMap['overallScore'] as num?)?.toInt() ?? 50;

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

  /// 사진 분석 + 변형을 한 번에 수행 — 분석 결과와 변형 이미지를 동시 반환
  Future<({String analysisJson, String imagePath, Map<String, dynamic> fullResult})>
      analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
  }) async {
    final processed = await _imageService.processImage(imageFile);

    final result = await _datasource.analyzeAndTransform(
      imageBase64: processed.base64,
      styleProfile: styleProfile ?? {},
      userId: userId,
    );

    final analysis = result['analysis'] as Map<String, dynamic>? ?? {};
    final analysisJson = jsonEncode(analysis);

    // DB에 저장
    final styleCategory =
        (analysis['toneReport']?['styleCategory'] as String?) ?? '분석완료';
    final colorTemp =
        (analysis['colorAnalysis']?['colorTemperature'] as String?) ?? 'neutral';
    final currentScore =
        (analysis['overallScore'] as num?)?.toInt() ?? 50;

    final appDir = await getApplicationDocumentsDirectory();
    final savedImagePath = p.join(
      appDir.path,
      'photos',
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await Directory(p.dirname(savedImagePath)).create(recursive: true);
    await processed.file.copy(savedImagePath);

    await _database.insertAnalysis(
      AnalysisRecordsCompanion.insert(
        imagePath: savedImagePath,
        analysisJson: analysisJson,
        overallScore: currentScore,
        styleCategory: styleCategory,
        colorTemperature: colorTemp,
      ),
    );

    return (
      analysisJson: analysisJson,
      imagePath: savedImagePath,
      fullResult: result,
    );
  }

  /// 사용자 대표 사진 base64 목록을 조회
  Future<List<String>> fetchReferenceImages(String userId) async {
    return _datasource.fetchReferenceImages(userId);
  }

  /// AI 분석 기반 자동 변형 — 이미지 처리 후 서버에 자동 변형 요청
  Future<Map<String, dynamic>> autoTransformPhoto({
    required File imageFile,
    required Map<String, dynamic> analysis,
    Map<String, dynamic>? styleProfile,
  }) async {
    final processed = await _imageService.processImage(imageFile);
    return _datasource.autoTransform(
      imageBase64: processed.base64,
      analysis: analysis,
      styleProfile: styleProfile,
    );
  }

  /// 슬라이더 값으로 수동 변형 — 원본 이미지에서 항상 새로 적용
  Future<Map<String, dynamic>> applyTransform({
    required File imageFile,
    double brightness = 0.0,
    double contrast = 0.0,
    double clarity = 0.0,
    double dehaze = 0.0,
    double highlights = 0.0,
    double shadows = 0.0,
    double saturation = 0.0,
    double temperature = 0.0,
    double blemishRemoval = 0.0,
    double skinSmoothing = 0.0,
    double vignette = 0.0,
    double sharpness = 0.0,
    double grain = 0.0,
    String toneCurvePreset = 'linear',
    double toneCurveStrength = 0.0,
    double splitShadowHue = 0.0,
    double splitShadowStrength = 0.0,
    double splitHighlightHue = 0.0,
    double splitHighlightStrength = 0.0,
    Map<String, Map<String, double>>? hslAdjust,
    double faceSlim = 0.0,
    double jawSharpen = 0.0,
    double eyeEnlarge = 0.0,
    double legStretch = 0.0,
    double shoulderWidth = 0.0,
    double waistSlim = 0.0,
  }) async {
    final processed = await _imageService.processImage(imageFile);
    return _datasource.applyTransform(
      imageBase64: processed.base64,
      brightness: brightness,
      contrast: contrast,
      clarity: clarity,
      dehaze: dehaze,
      highlights: highlights,
      shadows: shadows,
      saturation: saturation,
      temperature: temperature,
      blemishRemoval: blemishRemoval,
      skinSmoothing: skinSmoothing,
      vignette: vignette,
      sharpness: sharpness,
      grain: grain,
      toneCurvePreset: toneCurvePreset,
      toneCurveStrength: toneCurveStrength,
      splitShadowHue: splitShadowHue,
      splitShadowStrength: splitShadowStrength,
      splitHighlightHue: splitHighlightHue,
      splitHighlightStrength: splitHighlightStrength,
      hslAdjust: hslAdjust,
      faceSlim: faceSlim,
      jawSharpen: jawSharpen,
      eyeEnlarge: eyeEnlarge,
      legStretch: legStretch,
      shoulderWidth: shoulderWidth,
      waistSlim: waistSlim,
    );
  }
}
