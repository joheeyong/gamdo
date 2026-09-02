import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/services/database.dart';
import '../../../../core/services/image_service.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../claude_datasource.dart';

/// [AnalysisRepository] 구현체 — GamdoAgentDatasource + ImageService + DB.
class AnalysisRepositoryImpl implements AnalysisRepository {
  final GamdoAgentDatasource _datasource;
  final ImageService _imageService;
  final AppDatabase _database;

  AnalysisRepositoryImpl({
    required GamdoAgentDatasource datasource,
    required ImageService imageService,
    required AppDatabase database,
  })  : _datasource = datasource,
        _imageService = imageService,
        _database = database;

  @override
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts = const [],
    List<Map<String, dynamic>> feeds = const [],
    List<Map<String, dynamic>> stories = const [],
    String userId = '',
  }) {
    return _datasource.analyzeUser(
      posts: posts,
      feeds: feeds,
      stories: stories,
      userId: userId,
    );
  }

  @override
  Future<({String analysisJson, String imagePath, Map<String, dynamic> fullResult})>
      analyzeAndTransform({
    required File imageFile,
    Map<String, dynamic>? styleProfile,
    String userId = '',
    bool reshapeEnabled = false,
    CancelToken? cancelToken,
  }) async {
    final processed = await _imageService.processImage(imageFile);

    final result = await _datasource.analyzeAndTransform(
      imageBase64: processed.base64,
      styleProfile: styleProfile ?? {},
      userId: userId,
      reshapeEnabled: reshapeEnabled,
      cancelToken: cancelToken,
    );

    final analysis = result['analysis'] as Map<String, dynamic>? ?? {};
    final analysisJson = jsonEncode(analysis);

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

  @override
  Future<List<String>> fetchReferenceImages(String userId) {
    return _datasource.fetchReferenceImages(userId);
  }
}
