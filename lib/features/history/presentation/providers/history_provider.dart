import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/services/database.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(database: ref.watch(appDatabaseProvider));
});

final selectedStyleFilterProvider = StateProvider<String?>((ref) => null);

final filteredAnalysesProvider = StreamProvider<List<AnalysisRecord>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  final filter = ref.watch(selectedStyleFilterProvider);

  if (filter != null && filter.isNotEmpty) {
    return repo.watchByStyle(filter);
  }
  return repo.watchAll();
});
