import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(database: ref.watch(appDatabaseProvider));
});

final recentAnalysesProvider = StreamProvider<List<AnalysisRecord>>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.watchRecentAnalyses();
});
