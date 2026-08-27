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
    datasource: ClaudeRemoteDatasource(ref.read(dioProvider)),
    imageService: ref.read(imageServiceProvider),
    database: ref.read(appDatabaseProvider),
  );
}

class AnalysisRepository {
  final ClaudeRemoteDatasource _datasource;
  final ImageService _imageService;
  final AppDatabase _database;

  AnalysisRepository({
    required ClaudeRemoteDatasource datasource,
    required ImageService imageService,
    required AppDatabase database,
  })  : _datasource = datasource,
        _imageService = imageService,
        _database = database;

  Future<({int id, String analysisJson, String imagePath})> analyzePhoto(
      File imageFile) async {
    // 1. Process image
    final processed = await _imageService.processImage(imageFile);

    // 2. Save image to persistent storage
    final appDir = await getApplicationDocumentsDirectory();
    final savedImagePath = p.join(
      appDir.path,
      'photos',
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await Directory(p.dirname(savedImagePath)).create(recursive: true);
    await processed.file.copy(savedImagePath);

    // 3. Call Claude API
    final analysisMap = await _datasource.analyzeImage(processed.base64);

    // 4. Parse response
    final analysis = PhotoAnalysisResponse.fromJson(analysisMap);
    final analysisJson = jsonEncode(analysisMap);

    // 5. Save to database
    final id = await _database.insertAnalysis(
      AnalysisRecordsCompanion.insert(
        imagePath: savedImagePath,
        analysisJson: analysisJson,
        overallScore: analysis.overallScore,
        styleCategory: analysis.toneReport.styleCategory,
        colorTemperature: analysis.colorAnalysis.colorTemperature,
      ),
    );

    return (id: id, analysisJson: analysisJson, imagePath: savedImagePath);
  }
}
