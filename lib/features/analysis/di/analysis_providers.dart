import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/database.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/image_service.dart';
import '../data/claude_datasource.dart';
import '../data/datasources/firebase_datasource.dart';
import '../data/repositories/analysis_repository_impl.dart';
import '../data/repositories/style_repository_impl.dart';
import '../data/repositories/transform_repository_impl.dart';
import '../domain/repositories/analysis_repository.dart';
import '../domain/repositories/style_repository.dart';
import '../domain/repositories/transform_repository.dart';

// ── Datasource Providers ──

final gamdoAgentDatasourceProvider = Provider<GamdoAgentDatasource>((ref) {
  return GamdoAgentDatasource(ref.read(dioProvider));
});

final firebaseDatasourceProvider = Provider<FirebaseDatasource>((ref) {
  return FirebaseDatasource(ref.read(firebaseServiceProvider));
});

// ── Repository Providers (interface → impl 바인딩) ──

final analysisRepositoryDIProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepositoryImpl(
    datasource: ref.read(gamdoAgentDatasourceProvider),
    imageService: ref.read(imageServiceProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final transformRepositoryProvider = Provider<TransformRepository>((ref) {
  return TransformRepositoryImpl(
    datasource: ref.read(gamdoAgentDatasourceProvider),
    imageService: ref.read(imageServiceProvider),
  );
});

final styleRepositoryProvider = Provider<StyleRepository>((ref) {
  return StyleRepositoryImpl(
    datasource: ref.read(firebaseDatasourceProvider),
  );
});
